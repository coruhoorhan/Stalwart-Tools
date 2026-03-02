#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 --csv FILE --wave-id ID --src-host HOST --dst-host HOST [--check-password-env]

Checks:
  - required files/scripts exist
  - CSV header and wave rows
  - TCP reachability (src:993, dst:443)
  - optional env var presence: ZIMBRA_PASS, STALWART_PASS
USAGE
}

CSV=""
WAVE_ID=""
SRC_HOST=""
DST_HOST=""
CHECK_PASSWORD_ENV=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --csv) CSV="$2"; shift 2;;
    --wave-id) WAVE_ID="$2"; shift 2;;
    --src-host) SRC_HOST="$2"; shift 2;;
    --dst-host) DST_HOST="$2"; shift 2;;
    --check-password-env) CHECK_PASSWORD_ENV=1; shift 1;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

[[ -n "$CSV" && -n "$WAVE_ID" && -n "$SRC_HOST" && -n "$DST_HOST" ]] || { usage; exit 1; }

pass=0
warn=0
fail=0

ok()   { echo "[PASS] $*"; pass=$((pass+1)); }
ng()   { echo "[FAIL] $*"; fail=$((fail+1)); }
warnf(){ echo "[WARN] $*"; warn=$((warn+1)); }

check_tcp() {
  local host="$1" port="$2" label="$3"
  if timeout 3 bash -lc "</dev/tcp/${host}/${port}" >/dev/null 2>&1; then
    ok "$label reachable (${host}:${port})"
  else
    ng "$label not reachable (${host}:${port})"
  fi
}

[[ -f "$CSV" ]] && ok "CSV exists: $CSV" || ng "CSV not found: $CSV"
[[ -x "./smmailbox/smmailbox" ]] && ok "smmailbox executable exists" || ng "./smmailbox/smmailbox not executable"
[[ -x "./bin/migration-wave-runner.sh" ]] && ok "wave runner exists" || ng "./bin/migration-wave-runner.sh not executable"

if [[ -f "$CSV" ]]; then
  header="$(head -n1 "$CSV" | tr -d '\r')"
  if [[ "$header" == "source_user,target_user,wave_id,migration_method,status" ]]; then
    ok "CSV header is valid"
  else
    ng "CSV header invalid: $header"
  fi

  wave_rows=$(awk -F, -v w="$WAVE_ID" 'NR>1 && $3==w {c++} END{print c+0}' "$CSV")
  if [[ "$wave_rows" -gt 0 ]]; then
    ok "Wave rows found for $WAVE_ID: $wave_rows"
  else
    ng "No rows found for wave $WAVE_ID"
  fi
fi

check_tcp "$SRC_HOST" 993 "Zimbra IMAP"
check_tcp "$DST_HOST" 443 "Stalwart HTTPS/JMAP"

if [[ $CHECK_PASSWORD_ENV -eq 1 ]]; then
  [[ -n "${ZIMBRA_PASS:-}" ]] && ok "ZIMBRA_PASS set" || ng "ZIMBRA_PASS is not set"
  [[ -n "${STALWART_PASS:-}" ]] && ok "STALWART_PASS set" || ng "STALWART_PASS is not set"
else
  warnf "Password env check skipped (use --check-password-env)"
fi

echo ""
echo "Summary: pass=$pass warn=$warn fail=$fail"

if [[ $fail -gt 0 ]]; then
  echo "READY: NO"
  exit 2
fi

echo "READY: YES"

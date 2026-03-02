#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 --csv FILE --wave-id ID --mode delegated|reset|hybrid --src-host HOST --dst-host HOST [--dry-run]

CSV columns (header required):
  source_user,target_user,wave_id,migration_method,status

Required env vars (unless --dry-run):
  ZIMBRA_PASS
  STALWART_PASS
USAGE
}

CSV=""
WAVE_ID=""
MODE=""
SRC_HOST=""
DST_HOST=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --csv) CSV="$2"; shift 2;;
    --wave-id) WAVE_ID="$2"; shift 2;;
    --mode) MODE="$2"; shift 2;;
    --src-host) SRC_HOST="$2"; shift 2;;
    --dst-host) DST_HOST="$2"; shift 2;;
    --dry-run) DRY_RUN=1; shift 1;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

[[ -n "$CSV" && -n "$WAVE_ID" && -n "$MODE" && -n "$SRC_HOST" && -n "$DST_HOST" ]] || { usage; exit 1; }
[[ -f "$CSV" ]] || { echo "CSV not found: $CSV" >&2; exit 1; }

case "$MODE" in
  delegated|reset|hybrid) ;;
  *) echo "Invalid mode: $MODE" >&2; exit 1;;
esac

if [[ $DRY_RUN -eq 0 ]]; then
  : "${ZIMBRA_PASS:?ZIMBRA_PASS must be set}"
  : "${STALWART_PASS:?STALWART_PASS must be set}"
fi

RUN_TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="migration-logs/$WAVE_ID/$RUN_TS"
mkdir -p "$OUT_DIR"
SUMMARY="$OUT_DIR/summary.csv"
echo "source_user,target_user,wave_id,migration_method,result,logfile" > "$SUMMARY"

# skip header
{ read -r _header
  while IFS=',' read -r source_user target_user wave_id migration_method status; do
    [[ -z "${source_user:-}" ]] && continue
    [[ "$wave_id" != "$WAVE_ID" ]] && continue

    logfile="$OUT_DIR/${source_user//[@.]/_}.log"
    result="ok"

    cmd=(
      ./smmailbox/smmailbox
      clone-all
      --src-host "$SRC_HOST"
      --src-user "$source_user"
      --src-password-env ZIMBRA_PASS
      --dst-host "$DST_HOST"
      --dst-user "$target_user"
      --dst-password-env STALWART_PASS
    )

    if [[ $DRY_RUN -eq 1 ]]; then
      cmd=(./smmailbox/smmailbox --dry-run "${cmd[@]:1}")
    fi

    echo "[INFO] $source_user -> $target_user ($wave_id/$migration_method)" | tee -a "$logfile"
    if ! "${cmd[@]}" >> "$logfile" 2>&1; then
      result="fail"
    fi

    echo "$source_user,$target_user,$wave_id,$migration_method,$result,$logfile" >> "$SUMMARY"
  done
} < "$CSV"

echo "Run completed. Summary: $SUMMARY"

# Zimbra → Stalwart 200+ Kullanıcı Migrasyon Runbook (TR)

## Amaç
Bu runbook, kullanıcı şifrelerinin elde olmadığı senaryoda 200+ kullanıcı migration operasyonunu güvenli ve tekrarlanabilir şekilde yürütmek için hazırlanmıştır.

## Faz 0 — Ön Koşul Kontrolü

- [ ] Auth yöntemi seçildi: `delegated` / `reset` / `hybrid`
- [ ] Zimbra IMAP ve SOAP erişimi test edildi
- [ ] Stalwart hesap provisioning tamamlandı
- [ ] Pilot kullanıcı listesi hazırlandı
- [ ] Dalga CSV dosyası hazırlandı (`source_user,target_user,wave_id,migration_method,status`)


## Faz 0.5 — Hazır mı? (Tek komutla kontrol)

Aşağıdaki komut "mevcut kod hazır mı" sorusuna doğrudan **READY: YES/NO** cevabı verir:

```bash
bin/migration-readiness-check.sh \
  --csv pilot.csv \
  --wave-id W01 \
  --src-host zimbra.local \
  --dst-host stalwart.local
```

Şifre env değişkenlerini de doğrulamak için:

```bash
export ZIMBRA_PASS='...'
export STALWART_PASS='...'
bin/migration-readiness-check.sh \
  --csv pilot.csv \
  --wave-id W01 \
  --src-host zimbra.local \
  --dst-host stalwart.local \
  --check-password-env
```

## Faz 1 — Pilot (5–10 kullanıcı)

1. Pilot CSV üretin.
2. Dry-run başlatın.
3. Gerçek koşu başlatın.
4. Doğrulama checklist’i ile parity kontrolü yapın.
5. Go/No-Go kararı verin.

Örnek komut:

```bash
bin/migration-wave-runner.sh \
  --csv pilot.csv \
  --wave-id W01 \
  --mode delegated \
  --src-host zimbra.local \
  --dst-host stalwart.local \
  --dry-run
```

## Faz 2 — Dalgalı Geçiş

- Dalga başına öneri: 20–40 kullanıcı
- Her dalga sonrası rapor:
  - başarılı
  - kısmi
  - hatalı
- Hatalı kullanıcılar için tekrar kuyruğu açın.

## Faz 3 — Cutover ve Hypercare

- Delta sync tekrarı (cutover öncesi)
- DNS/MX/istemci yönlendirme
- 3–7 gün hypercare
- Eksik metadata/mail onarım koşuları

## Rollback Prensibi

- Hedef kullanıcı problemi çözülemezse kaynak sistem aktif tutulur.
- Dalga bazlı rollback değerlendirilir; tüm tenant rollback son çare olmalıdır.

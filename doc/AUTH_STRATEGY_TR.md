# Auth Strategy (TR): Şifre Yok Senaryosu

## 1) Delegated/Admin Auth
**Avantaj:** Kullanıcı şifresi toplamadan migration.
**Risk:** Kurumsal politikada kapalı olabilir.
**Doğrulama:** IMAP + SOAP ikisinde de PoC şart.

## 2) Geçici Toplu Reset
**Avantaj:** En garanti fallback yöntemi.
**Risk:** Helpdesk yükü, güvenlik ve iletişim yönetimi.
**Doğrulama:** Pilot dalgada parola yaşam döngüsü testi.

## 3) Hibrit
**Avantaj:** Mail tarafı hızlanır.
**Risk:** Metadata tarafı parçalı kalabilir.
**Doğrulama:** Kapsam matrisini yazılı yönetin.

## Karar Kuralı
- IMAP+SOAP delegated varsa: **Delegated**
- Sadece IMAP delegated varsa: **Hibrit**
- İkisi de yoksa: **Reset**

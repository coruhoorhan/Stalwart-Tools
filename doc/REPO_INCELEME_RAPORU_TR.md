# Stalwart-Tools Repo İnceleme + 200+ Kullanıcı Migrasyon Analizi (TR)

Bu rapor, deponun mevcut yapısını teknik olarak özetler ve özellikle **200+ kullanıcılı, kullanıcı şifreleri elde olmayan** Zimbra → Stalwart geçişi için uygulanabilir çözüm yolunu verir.

## 1) Kısa Teşhis

- `smmailbox` teknik olarak güçlü bir taşıma aracıdır (mail + tags + filters + contacts + calendars).
- Ancak sizdeki kritik problem: **200 kullanıcının şifresi yok**.
- Bu durumda doğrudan toplu migration yapmak yerine önce **kimlik doğrulama (auth) problemini** çözmek gerekir.

## 2) Net Çözüm Yolu (Özet)

Aşağıdaki 3 seçenekten biri çözülmeden migration başlatmayın:

1. **Delegated/Admin Auth (tercih edilen)**
   - Zimbra’da IMAP + SOAP için admin üzerinden kullanıcı adına yetkili erişim.
2. **Geçici Toplu Şifre Reset Planı**
   - Geçiş penceresi için geçici parola seti, cutover sonrası zorunlu parola değişimi.
3. **Hibrit**
   - Mail’i admin/delegated ile taşı, metadata (filter/contact/calendar) için kontrollü reset/oturum açma dalgası uygula.

---

## 3) Adım Adım Operasyon Planı (Gerçekçi, Uygulanabilir)

## Faz 0 — Karar ve Hazırlık (1–2 gün)

### 0.1 Auth modelini karar altına al
- Güvenlik + altyapı ekipleriyle aşağıdakini netleştir:
  - IMAP delegated/admin auth var mı?
  - SOAP tarafında kullanıcı adına erişim modeli var mı?
- Çıktı: “Hangi yöntemle kimlik doğrulama yapılacak?” tek cümlelik resmi karar.

### 0.2 Başarı kriterlerini yazılı hale getir
- Teknik başarı kriterleri:
  - Mail item sayısı parity (kaynak/hedef tolerans eşiği)
  - Klasör parity
  - En az %95 metadata başarı hedefi (filter/contact/calendar)
- Operasyon kriterleri:
  - Pilotta kritik P1 hata sayısı
  - Helpdesk ticket üst sınırı

### 0.3 Kapsamı dondur
- İlk dalgada taşınacaklar: mail + folder + flags + tags + filters + contacts + calendars
- İlk dalgada taşınmayacaklar (ayrı plan): shared folders, DL, aliases

---

## Faz 1 — Teknik PoC (5–10 kullanıcı)

### 1.1 PoC kullanıcı seti seç
- Farklı profil seç:
  - küçük mailbox
  - büyük mailbox
  - yoğun filtre kullanan
  - takvim/kişi yoğun kullanıcı

### 1.2 `smmailbox` dry-run + gerçek koşu
- Önce `--dry-run`
- Sonra gerçek `clone-all`
- Aynı host adlarını kullan (idempotency/tekrar koşu açısından)

### 1.3 PoC doğrulama checklist’i
- Mail sayısı
- Klasör yapısı
- Etiket ad/renk görünümü
- Filtrelerin doğru import edilmesi
- Kişi ve takvim örneklem doğrulaması

### 1.4 Go/No-Go kapısı
- PoC geçmezse **200 kullanıcı planını başlatmayın**.
- En sık hata tipleri ve çözümleri runbook’a girilmeden dalgaya çıkmayın.

---

## Faz 2 — Altyapı Otomasyonu (Toplu Geçiş Öncesi)

### 2.1 Hedef hesap provisioning
- Stalwart tarafında kullanıcı hesaplarını toplu oluşturun.
- Gerekli policy/quota/default yapılarını standartlaştırın.

### 2.2 Dalga dosyası oluştur
- CSV örneği:
  - source_user
  - target_user
  - wave_id
  - migration_method (delegated/reset)
  - status

### 2.3 Log ve raporlama standardı
- Her kullanıcı koşusunun çıktı logunu saklayın.
- “Başarılı / Kısmi / Hatalı” sınıflandırması yapın.

---

## Faz 3 — 200 Kullanıcı Dalgalı Geçiş

### 3.1 Dalga boyutu
- 20–40 kullanıcı/dalga ile başlayın.
- İlk iki dalgada küçük tutun (öğrenme etkisi için).

### 3.2 Delta senkron
- Cutover’dan önce farkı azaltmak için `imapsync` tekrar koşuları yapın.

### 3.3 Cutover operasyonu
- DNS/MX/istemci yönlendirme planını değişiklik penceresinde uygulayın.
- Kısa dondurma penceresi ile veri tutarlılığını koruyun.

### 3.4 Hypercare (3–7 gün)
- Öncelikli ticket kuyruğu açın.
- Eksik veri/metadata onarım prosedürü çalıştırın.

---

## 4) Şifre Yok Problemi İçin Pratik Karar Tablosu

- **Delegated + SOAP mümkünse:** En temiz yol, bu modelle ilerleyin.
- **Sadece IMAP delegated mümkünse:** Mail taşınır; metadata için ek plan gerekir.
- **Hiçbiri mümkün değilse:** Kontrollü geçici toplu reset tek gerçekçi kurumsal yol.

---

## 5) Bu Repoda Somut Olarak Ne Eklenmeli?

Bu sorunu gerçekten çözmek için repoya eklenmesi önerilen somut çıktılar:

1. `doc/MIGRATION_RUNBOOK_200_USERS_TR.md`
   - Fazlara bölünmüş adımlar
   - Go/No-Go kriterleri
   - Incident/rollback akışı
2. `bin/migration-wave-runner.sh` (veya py)
   - CSV’den kullanıcı okuyup dalga bazlı koşu
   - Başarı/hata kodu üretimi
3. `doc/MIGRATION_CHECKLIST_TR.md`
   - Öncesi/sırası/sonrası kontrol listesi
4. `doc/AUTH_STRATEGY_TR.md`
   - Delegated auth vs reset yaklaşımı karar matrisi

---

## 6) Hızlı Sonuç

Sizin sorununuzun cevabı “tool var” değil, **“auth modeli çözülmeden migration başlamaz”** olmalı.

Bu yüzden doğru sıra:
1. Auth kararını ver,
2. PoC ile doğrula,
3. Hesap otomasyonunu hazırla,
4. Dalgalı geçişe çık.

İsterseniz bir sonraki adımda bu repoya doğrudan:
- `MIGRATION_RUNBOOK_200_USERS_TR.md`
- `MIGRATION_CHECKLIST_TR.md`
şablonlarını da ekleyebilirim.

# Libris - Kütüphane Otomasyonu

Libris, kitapları, kullanıcıları ve ödünç alma işlemlerini takip ve düzenleme imkanı sunan bir kütüphane otomasyon sistemidir. Flutter ve SQLite kullanılarak geliştirilmiştir ve Windows platformunda çalışmaktadır. Libris, kullanıcı dostu arayüzü ve güçlü veritabanı yönetimi ile kütüphanelerinizi kolayca yönetmenizi sağlar.

## Özellikler

- **Kitap Yönetimi**
  - Kitaplar sayfasında yeni kitaplar ekleyebilir, mevcut kitapları düzenleyebilir ve silebilirsiniz.
  - Kitaplar, başlık, yazar, kategori gibi çeşitli alanlarla düzenlenebilir.
  - Arama ve filtreleme özellikleri ile kitapları hızlıca bulabilir ve ihtiyaçlarınıza göre sıralayabilirsiniz.

- **Kullanıcı Yönetimi**
  - Kullanıcılar sayfasında kullanıcıları ekleyebilir, düzenleyebilir ve silebilirsiniz.
  - Kullanıcı bilgileri (ad, soyad, e-posta vb.) düzenlenebilir.

- **Ödünç Alma ve İade**
  - Kullanıcılar kitapları ödünç alabilir ve geri verebilir.
  - Ödünç alma işlemleri, ödünç alınan kitaplar ve geri getirme tarihleri veritabanında saklanır.
  - Anasayfa üzerinden hızlı işlemlerle kitap alıp verebilirsiniz.

- **Veritabanı Yönetimi**
  - SQLite veritabanı kullanarak kitaplar, kullanıcılar ve ödünç alma işlemleri güvenli bir şekilde depolanır.
  - Veritabanı, kitaplar ve kullanıcılar arasındaki ilişkiyi yönetir ve işlem geçmişini takip eder.

## Kurulum

### Gereksinimler

- **Windows** işletim sistemi
- **Flutter SDK** (Flutter uygulamasını çalıştırmak için)
- **SQLite** (Veritabanı yönetimi için)

### Adımlar

1. **GitHub'dan Kodu İndirme**

   Projeyi GitHub üzerinden indirebilirsiniz. `setup.exe` dosyasını indirip kurulum adımlarını takip edebilir ya da kaynak kodlarını GitHub'dan indirip Flutter ortamınızda çalıştırabilirsiniz.

2. **setup.exe ile Kurulum**
   - `setup.exe` dosyasını indirin ve çalıştırın.
   - Yönergeleri takip ederek kurulumu tamamlayın.

3. **Açık Kaynak Kodları Kullanma**
   - GitHub'dan projeyi klonlayın:
   
     ```bash
     git clone https://github.com/<username>/libris.git
     ```

   - Flutter bağımlılıklarını yükleyin:
   
     ```bash
     flutter pub get
     ```

   - Uygulamayı başlatın:
   
     ```bash
     flutter run
     ```

   **Not:** Diğer platformlar (macOS, Linux, Android, iOS) için test edilmediği için sadece Windows üzerinde çalıştığından emin olunmuştur.

## Kullanım

1. **Ana Menü:**
   - Başlangıçta, kullanıcılar ana menüye ulaşır. Buradan **Kitaplar**, **Kullanıcılar**, ve **Ödünç Alma İşlemleri** sayfalarına geçiş yapılabilir.
   - **Anasayfa** üzerinden hızlıca kitap alıp verebilirsiniz.

2. **Kitaplar Sayfası:**
   - **Kitap Ekle:** Yeni kitaplar eklemek için "Kitap Ekle" butonuna tıklayabilirsiniz.
   - **Arama ve Filtreleme:** Kitaplar arasında arama yapabilir ve filtreleme seçenekleriyle ihtiyacınıza göre listeyi daraltabilirsiniz.
   - **Kitap Düzenleme:** Mevcut kitapları düzenleyebilir veya silebilirsiniz.

3. **Kullanıcılar Sayfası:**
   - Kullanıcılar sayfasında mevcut kullanıcıları görebilir, yeni kullanıcılar ekleyebilir veya mevcut kullanıcıları düzenleyebilirsiniz.

4. **Ödünç Alma ve İade:**
   - **Ödünç Alma:** Kitap ödünç almak için kullanıcıya ait bir kitap seçebilir ve ödünç alma işlemi başlatılabilir.
   - **İade Etme:** Ödünç alınan kitapları geri alabilir ve ilgili işlemi tamamlayabilirsiniz.

## Veritabanı Yapısı

Libris, SQLite veritabanını kullanarak üç ana tabloyu yönetir:

- **Books Tablosu:** Kitap bilgilerini içerir (ID, başlık, yazar, kategori vb.).
- **Users Tablosu:** Kullanıcı bilgilerini içerir (ID, ad, soyad, e-posta vb.).
- **Transactions Tablosu:** Ödünç alma ve iade işlemlerini kaydeder (kitap ID'si, kullanıcı ID'si, ödünç alınma tarihi, geri getirme tarihi vb.).

## Katkı Sağlama

Libris'e katkı sağlamak isterseniz, aşağıdaki adımları izleyebilirsiniz:

1. Bu projeyi fork edin.
2. Kendi dalınızı oluşturun (`git checkout -b feature-xyz`).
3. Değişikliklerinizi yapın ve commit edin (`git commit -am 'Add new feature'`).
4. Pull request oluşturun.

## Lisans

Bu proje **GPL** açık kaynak lisansı ile lisanslanmıştır.

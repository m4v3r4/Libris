# Libris — Kütüphane Yönetim Sistemi

Libris; kitap, üye ve emanet işlemlerini yerel olarak yönetmek için Flutter ile geliştirilmiş, SQLite tabanlı bir kütüphane yönetim uygulamasıdır. İnternet bağlantısı veya merkezi bir sunucu gerektirmeden çalışabilir.

## Özellikler

### 📚 Kitap Yönetimi
- Kitap ekleme, düzenleme ve silme
- Kitap listeleme ve detay görüntüleme
- Kategori ve raf/konum bilgisi
- En çok okunan ve son eklenen kitap istatistikleri

### 👥 Üye Yönetimi
- Üye ekleme, güncelleme ve silme
- İsim, telefon veya e-posta ile arama
- En aktif ve son eklenen üyeler

### 🔄 Emanet İşlemleri
- Kitap ödünç verme ve iade alma
- Aktif, gecikmiş ve iade edilmiş emanet takibi
- Kitap ve üye seçimi için arama
- Tarih ve durum filtreleme
- Aynı kitabın eşzamanlı olarak ikinci kez emanet verilmesini engelleyen stok kontrolü

### 📊 Dashboard
- Kütüphanenin genel durumunu özetleyen kartlar
- Kitap, üye ve emanet istatistikleri
- Hızlı erişim menüsü

### 🗄️ Veritabanı Araçları
- SQLite veritabanı görüntüleme ve düzenleme
- JSON / CSV / Excel içe-dışa aktarma araçları
- Kategori yönetimi

## Teknolojiler

- **Dil:** Dart
- **Framework:** Flutter
- **Veritabanı:** SQLite
- **State management:** Provider
- **Mimari:** Feature-based yapı + ortak veritabanı servis katmanı

```text
lib/
├── common/
│   ├── database/
│   ├── models/
│   ├── providers/
│   ├── services/
│   ├── theme/
│   └── widgets/
├── features/
│   ├── books/
│   ├── members/
│   ├── loans/
│   ├── home/
│   ├── settings/
│   └── dbeditor/
└── main.dart
```

## Platform Desteği

Libris'in ana hedefi masaüstü kullanımıdır.

| Platform | Durum |
| --- | --- |
| Windows | ✅ Ana hedef |
| Linux | ✅ Destekleniyor |
| macOS | ✅ Destekleniyor |
| Android | 🧪 Deneysel |
| iOS | 🧪 Deneysel |
| Web | ❌ SQLite mimarisi nedeniyle desteklenmiyor |

Masaüstünde `sqflite_common_ffi`, Android ve iOS'ta standart `sqflite` kullanılır.

## Kurulum

Gereksinim: Flutter stable. v1.1 stabilizasyon çalışmaları Flutter **3.41.9 / Dart 3.11.5** ile doğrulanmaktadır.

```bash
git clone https://github.com/m4v3r4/Libris.git
cd Libris
flutter pub get
flutter analyze
flutter test
flutter run
```

Windows üzerinde çalıştırmak için örneğin:

```bash
flutter run -d windows
```

## Geliştirme

Her push ve pull request'te GitHub Actions üzerinden:

```text
flutter pub get
flutter analyze
flutter test
```

çalıştırılır.

## Roadmap

Aktif geliştirme yol haritası GitHub Issues üzerinde tutuluyor:

- [Libris Roadmap — önce toparla, sonra eğleniriz 😄](https://github.com/m4v3r4/Libris/issues/31)

Mevcut kararlı sürüm: **v1.0.1**

# Libris - Kütüphane Yönetim Sistemi

Libris, kütüphane operasyonlarını kolaylaştırmak, kitap takibini sağlamak ve üye yönetimini dijitalleştirmek amacıyla Flutter kullanılarak geliştirilmiş modern bir mobil uygulamadır. Veri saklama işlemi için yerel SQLite veritabanı kullanır.

## 🚀 Özellikler

### 📚 Kitap Yönetimi
*   Yeni kitap ekleme, düzenleme ve silme.
*   Kitap listeleme ve detay görüntüleme.
*   En çok okunan ve son eklenen kitap istatistikleri.

### 👥 Üye Yönetimi
*   Üye kaydı oluşturma, güncelleme ve silme.
*   İsim, telefon veya e-posta ile gelişmiş üye arama.
*   En aktif üyeler (en çok kitap okuyanlar) ve yeni üyeler listesi.

### 🔄 Emanet (Loan) İşlemleri
*   Kitap ödünç verme ve iade alma süreçleri.
*   **Akıllı Arama:** Emanet verirken kitap ve üyeleri açılır pencerede arayarak seçme.
*   **Durum Takibi:** Aktif, gecikmiş ve iade edilmiş emanetlerin görsel olarak ayrıştırılması.
*   **Filtreleme:** Tarih aralığına ve emanet durumuna (Gecikmiş, Emanette vb.) göre listeleme.
*   Stok kontrolü (Emanetteki kitap tekrar verilemez).

### 📊 Dashboard (Ana Sayfa)
*   Hızlı erişim menüsü (Sol bar).
*   Özet istatistikler (Widget'lar üzerinden anlık veri takibi).

## 🛠 Teknolojiler ve Mimari

Bu proje **Flutter** ile geliştirilmiş olup, özellik tabanlı (feature-based) bir klasör yapısına sahiptir.

*   **Dil:** Dart
*   **Framework:** Flutter
*   **Veritabanı:** SQLite (`sqflite` paketi)
*   **Mimari:** Service-Repository Pattern benzeri bir yapı kullanılmıştır. Her özelliğin (Books, Members, Loans) kendi servisi ve modeli bulunur.

### Klasör Yapısı

```text
lib/
├── common/             # Genel yardımcı sınıflar (DatabaseHelper vb.)
├── features/           # Uygulama özellikleri
│   ├── books/          # Kitap modelleri, servisleri ve ekranları
│   ├── members/        # Üye modelleri, servisleri ve ekranları
│   ├── loans/          # Emanet modelleri, servisleri ve ekranları
│   └── home/           # Ana sayfa ve dashboard widget'ları
└── main.dart           # Uygulama giriş noktası
```

## 📸 Kurulum ve Çalıştırma

Projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları izleyin:

1.  **Depoyu klonlayın:**
    ```bash
    git clone https://github.com/kullaniciadi/libris.git
    cd libris
    ```

2.  **Bağımlılıkları yükleyin:**
    ```bash
    flutter pub get
    ```

3.  **Uygulamayı çalıştırın:**
    Bir emülatör veya fiziksel cihaz bağladıktan sonra:
    ```bash
    flutter run
    ```

## 🗺️ Roadmap

Projenin yol haritası GitHub Issues üzerinden yönetilmektedir.

👉 https://github.com/m4v3r4/libris/issues?q=label:roadmap



Libris v1.0

# Libris – Library Management System | Kütüphane Yönetim Sistemi

> **Libris** is a modern, open-source **library management mobile application** built with **Flutter**. It simplifies book tracking, member management, and loan operations using a fast and reliable **SQLite** local database.
>
> **Libris**, **Flutter** ile geliştirilmiş modern ve açık kaynaklı bir **kütüphane yönetim sistemi** mobil uygulamasıdır. Kitap takibi, üye yönetimi ve emanet işlemlerini **SQLite** yerel veritabanı ile kolaylaştırır.

---

## 🌍 About Libris | Libris Hakkında

**Libris Library Management System** is designed for small to medium-sized libraries, schools, and personal collections. It focuses on usability, offline-first architecture, and clean modular code structure.

**Libris Kütüphane Yönetim Sistemi**, küçük ve orta ölçekli kütüphaneler, okullar ve kişisel koleksiyonlar için tasarlanmıştır. Kullanıcı dostu arayüz, offline çalışma ve modüler mimariyi hedefler.

---

## 🚀 Features | Özellikler

### 📚 Book Management | Kitap Yönetimi

* Add, edit, and delete books

* Book listing and detailed view

* Most read and recently added book statistics

* Yeni kitap ekleme, düzenleme ve silme

* Kitap listeleme ve detay görüntüleme

* En çok okunan ve son eklenen kitap istatistikleri

---

### 👥 Member Management | Üye Yönetimi

* Create, update, and delete members

* Advanced search by name, phone, or email

* Most active and newly registered members

* Üye kaydı oluşturma, güncelleme ve silme

* İsim, telefon veya e-posta ile gelişmiş arama

* En aktif ve yeni üyeler listesi

---

### 🔄 Loan Management | Emanet İşlemleri

* Book borrowing and return workflows

* Smart search modal for books and members

* Visual loan status tracking (active, overdue, returned)

* Filtering by date range and loan status

* Stock control (borrowed books cannot be re-loaned)

* Kitap ödünç verme ve iade alma süreçleri

* Kitap ve üyeler için akıllı arama penceresi

* Aktif, gecikmiş ve iade edilmiş emanetlerin takibi

* Tarih ve durum bazlı filtreleme

* Stok kontrolü (emanetteki kitap tekrar verilemez)

---

### 📊 Dashboard | Ana Sayfa

* Quick access side navigation

* Real-time statistics widgets

* Hızlı erişim menüsü (sol bar)

* Anlık istatistikler (widget tabanlı)

---

## 🛠 Tech Stack & Architecture | Teknolojiler ve Mimari

**Libris** is built using a **feature-based architecture** for scalability and maintainability.

**Libris**, ölçeklenebilir ve sürdürülebilir bir yapı için **feature-based mimari** kullanır.

* **Language / Dil:** Dart
* **Framework:** Flutter
* **Database / Veritabanı:** SQLite (`sqflite`)
* **Architecture / Mimari:** Service–Repository Pattern

Each feature (Books, Members, Loans) has its own models, services, and UI layers.

---

### 📁 Project Structure | Klasör Yapısı

```text
lib/
├── common/             # Shared utilities (DatabaseHelper, constants)
├── features/           # Feature-based modules
│   ├── books/          # Book models, services, and screens
│   ├── members/        # Member models, services, and screens
│   ├── loans/          # Loan models, services, and screens
│   └── home/           # Dashboard & home widgets
└── main.dart           # Application entry point
```

---

## ⚙️ Installation & Run | Kurulum ve Çalıştırma

### Requirements | Gereksinimler

* Flutter SDK
* Android Studio or VS Code
* Emulator or physical device

### Steps | Adımlar

1. **Clone the repository / Depoyu klonlayın**

```bash
git clone https://github.com/m4v3r4/libris.git
cd libris
```

2. **Install dependencies / Bağımlılıkları yükleyin**

```bash
flutter pub get
```

3. **Run the application / Uygulamayı çalıştırın**

```bash
flutter run
```

---

## 🗺️ Roadmap

The project roadmap is managed via **GitHub Issues**.

Projenin yol haritası **GitHub Issues** üzerinden yönetilmektedir.

👉 [https://github.com/m4v3r4/libris/issues?q=label:roadmap](https://github.com/m4v3r4/libris/issues?q=label:roadmap)

---

## 📄 License | Lisans

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

Bu proje **GNU General Public License v3.0 (GPL-3.0)** ile lisanslanmıştır.

---

**Libris v1.0**

Flutter • SQLite • Open Source Library Management System

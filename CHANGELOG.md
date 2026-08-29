# Changelog

## Unreleased - v1.2.0

### Added
- Physical book copy / stock tracking through a new `book_copies` table.
- Unique inventory/barcode identifiers for every physical copy.
- Copy-level states: available, loaned, lost, and maintenance.
- Copy management directly from the book detail screen.
- Copy inventory codes on loan cards and detailed loan queries.
- Regression tests for copy creation, availability, multi-copy loans, returns, deletion rules, and legacy data backfill.
- Refreshed Libris branding assets for in-app, Android, and Windows use.
- Configurable dashboard panels with persisted visibility, size, and ordering.
- Functional Turkish and English runtime localization.
- Community contribution, conduct, security, issue, and pull-request guidance.
- Current UI screenshots in the project README.

### Changed
- Loans now reference a specific physical copy through nullable `loans.copyId`.
- A bibliographic book remains available as long as at least one physical copy is available.
- Multiple copies of the same title can be loaned at the same time.
- Active loans lock their physical copy until the loan is returned or deleted.
- New books automatically receive one initial physical copy.
- Application version updated to `1.2.0+4`.
- Redesigned the desktop application shell, navigation, dashboard, books, members, loans, categories, settings, and database tools.
- Refined light and dark theme surfaces, cards, inputs, dialogs, status treatments, and empty states.
- Language changes now apply immediately and persist locally across restarts.
- Built-in Material controls and date pickers now follow the selected Turkish or English locale.

### Compatibility
- Existing v1.1 books are preserved and receive an automatically generated initial copy.
- Existing loan history is preserved and linked to the generated copy where possible.
- The postponed DB v2 migration system is not introduced by this release; the database continues using the current v1.x initialization approach.

## v1.1.0 - 2026-08-28

### Fixed
- Aktif bir emanet kaydı silindiğinde ilgili kitabın tekrar müsait duruma dönmesi sağlandı.
- Emanet iade akışı transaction içinde daha güvenli hale getirildi.
- Kullanıcıya görünen bozuk Türkçe karakter ve encoding sorunları temizlendi.
- Async işlemler sonrasında `BuildContext` kullanımındaki analyzer uyarıları giderildi.
- Deprecated `withOpacity` kullanımları güncel Flutter API'sine taşındı.

### Changed
- `Member.dart` dosyası Dart dosya adlandırma standardına uygun olarak `member.dart` yapıldı.
- SQLite başlangıcı platforma göre ayrıldı; masaüstünde FFI, Android/iOS'ta standart sqflite kullanılıyor.
- Web hedefi v1.x için desteklenmediğinden web platform iskeleti kaldırıldı.
- `.gitignore` Flutter build/cache, IDE, platform çıktıları, yerel veritabanları ve export dosyaları için genişletildi.
- README ve proje metadata'sı güncellendi.
- Kullanılmayan `cupertino_icons` bağımlılığı kaldırıldı.
- Uygulama sürümü `1.1.0+3` olarak güncellendi.

### Tests / CI
- Takılan eski widget smoke testi kaldırıldı.
- Kritik emanet ve veri bütünlüğü akışları için in-memory SQLite testleri eklendi.
- GitHub Actions ile `flutter analyze` ve `flutter test` kontrolleri eklendi.
- Windows, Linux ve macOS için gerçek debug build smoke testleri eklendi.

## v1.0.1 - 2026-02-15
- Patch release for Libris v1.0.
- Fixed loan return bug by guarding against null loan IDs before return operation.
- Improved loan list integration with DatabaseProvider and embedded close handling.
- General UI/theme and dashboard refinements included in this patch.

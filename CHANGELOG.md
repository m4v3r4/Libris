# Changelog

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

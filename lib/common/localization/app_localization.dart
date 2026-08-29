import 'package:libris/features/settings/services/settings_service.dart';

/// Lightweight runtime localization for Libris.
///
/// The selected language is persisted by [SettingsService]. Keeping this
/// helper dependency-free avoids pulling a localization package into a small,
/// offline-first desktop application.
String l10n(String tr, String en) {
  return appLanguageNotifier.value == 'en' ? en : tr;
}

bool get isEnglish => appLanguageNotifier.value == 'en';

String l10nCount(int count, String trSingular, String trPlural, String enSingular, String enPlural) {
  if (isEnglish) {
    return '$count ${count == 1 ? enSingular : enPlural}';
  }
  return '$count ${count == 1 ? trSingular : trPlural}';
}

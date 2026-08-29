import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/widgets/section_toolbar.dart';
import 'package:libris/features/dbeditor/screen/database_home_screen.dart';
import 'package:libris/features/settings/services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  final bool embedded;
  final VoidCallback? onClose;

  const SettingsScreen({super.key, this.embedded = false, this.onClose});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();

    void close() {
      if (embedded) {
        onClose?.call();
      } else {
        Navigator.maybePop(context);
      }
    }

    return Scaffold(
      body: Column(
        children: [
          SectionToolbar(
            title: l10n('Ayarlar', 'Settings'),
            subtitle: l10n(
              'Görünüm, dil ve yerel veri seçeneklerini yönetin.',
              'Manage appearance, language, and local data options.',
            ),
            icon: Icons.settings_rounded,
            count: 3,
            onClose: close,
            leadingIcon:
                embedded ? Icons.close_rounded : Icons.arrow_back_rounded,
            leadingTooltip: embedded ? l10n('Kapat', 'Close') : l10n('Geri', 'Back'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const _BrandCard(),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: l10n('Görünüm', 'Appearance'),
                  children: [
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: appThemeNotifier,
                      builder: (context, currentMode, child) {
                        final isDark = currentMode == ThemeMode.dark;
                        return SwitchListTile(
                          secondary: Icon(
                            isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                          ),
                          title: Text(l10n('Karanlık Mod', 'Dark Mode')),
                          subtitle: Text(
                            isDark ? l10n('Açık', 'On') : l10n('Kapalı', 'Off'),
                          ),
                          value: isDark,
                          onChanged: (value) {
                            settingsService.saveTheme(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ValueListenableBuilder<String>(
                      valueListenable: appLanguageNotifier,
                      builder: (context, currentLang, child) {
                        return ListTile(
                          leading: const Icon(Icons.language_rounded),
                          title: Text(l10n('Dil', 'Language')),
                          subtitle: Text(
                            currentLang == 'tr' ? 'Türkçe' : 'English',
                          ),
                          trailing: DropdownButton<String>(
                            value: currentLang,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: 'tr',
                                child: Text('Türkçe'),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('English'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                settingsService.saveLanguage(value);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: l10n('Veri', 'Data'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.storage_rounded),
                      title: Text(l10n('Veritabanı Yöneticisi', 'Database Manager')),
                      subtitle: Text(
                        l10n(
                          'Tabloları görüntüle ve düzenle',
                          'View and edit database tables',
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DatabaseHomeScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Libris',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(l10n('Uygulama Hakkında', 'About Libris')),
                      subtitle: const Text('Libris v1.2.0'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        title: Row(
          children: [
            Image.asset(
              'assets/branding/libris-icon-128.png',
              width: 46,
              height: 46,
              filterQuality: FilterQuality.high,
              semanticLabel: l10n('Libris logosu', 'Libris logo'),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Libris')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n('Sürüm 1.2.0', 'Version 1.2.0'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                l10n(
                  'Kitapları, fiziksel kopyaları, üyeleri ve emanetleri yerel olarak yöneten offline-first kütüphane uygulaması.',
                  'An offline-first library application for managing books, physical copies, members, and loans locally.',
                ),
              ),
              const SizedBox(height: 14),
              Text(l10n('Özgür yazılım · GNU GPL v3.0', 'Free software · GNU GPL v3.0')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n('Kapat', 'Close')),
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/branding/libris-icon-128.png',
            width: 64,
            height: 64,
            filterQuality: FilterQuality.high,
            semanticLabel: l10n('Libris logosu', 'Libris logo'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Libris',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n(
                    'Basit, yerel ve çevrimdışı kütüphane yönetimi.',
                    'Simple, local, and offline library management.',
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'v1.2.0',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

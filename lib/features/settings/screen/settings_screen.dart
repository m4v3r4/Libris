import 'package:flutter/material.dart';
import 'package:libris/features/dbeditor/screen/database_home_screen.dart';
import 'package:libris/features/settings/services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  final bool embedded;
  final VoidCallback? onClose;

  const SettingsScreen({super.key, this.embedded = false, this.onClose});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: embedded
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose ?? () => Navigator.of(context).pop(),
              )
            : null,
        title: embedded ? null : const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeNotifier,
            builder: (context, currentMode, child) {
              final isDark = currentMode == ThemeMode.dark;
              return SwitchListTile(
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Karanlık Mod'),
                subtitle: Text(isDark ? 'Açık' : 'Kapalı'),
                value: isDark,
                onChanged: (value) {
                  settingsService.saveTheme(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              );
            },
          ),
          const Divider(),
          ValueListenableBuilder<String>(
            valueListenable: appLanguageNotifier,
            builder: (context, currentLang, child) {
              return ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Dil'),
                subtitle: Text(currentLang == 'tr' ? 'Türkçe' : 'English'),
                trailing: DropdownButton<String>(
                  value: currentLang,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'tr', child: Text('TR')),
                    DropdownMenuItem(value: 'en', child: Text('EN')),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.blueGrey),
            title: const Text('Veritabanı Yöneticisi'),
            subtitle: const Text('Tabloları görüntüle ve düzenle'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabaseHomeScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Uygulama Hakkında'),
            subtitle: const Text('Libris v1.0.1'),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.library_books),
                      SizedBox(width: 8),
                      Text('Libris'),
                    ],
                  ),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sürüm: 1.0.1',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        Text('© 2026 Libris Kütüphane Yönetim Sistemi'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Kapat'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

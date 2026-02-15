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
                title: const Text('Karanlik Mod'),
                subtitle: Text(isDark ? 'Acik' : 'Kapali'),
                value: isDark,
                onChanged: (val) {
                  settingsService.saveTheme(val ? ThemeMode.dark : ThemeMode.light);
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
                subtitle: Text(currentLang == 'tr' ? 'Turkce' : 'English'),
                trailing: DropdownButton<String>(
                  value: currentLang,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'tr', child: Text('TR')),
                    DropdownMenuItem(value: 'en', child: Text('EN')),
                  ],
                  onChanged: (val) {
                    if (val != null) settingsService.saveLanguage(val);
                  },
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.blueGrey),
            title: const Text('Veritabani Yoneticisi'),
            subtitle: const Text('Tablolari goruntule ve duzenle'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DatabaseHomeScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Uygulama Hakkinda'),
            subtitle: const Text('Libris v1.0.1'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
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
                        Text('Surum: 1.0.1', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('© 2023 Libris Kutuphane Yonetim Sistemi'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
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



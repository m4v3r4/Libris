import 'package:flutter/material.dart';
import 'package:libris/features/settings/services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsService settingsService = SettingsService();

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          // TEMA AYARI (SWITCH)
          ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeNotifier,
            builder: (context, currentMode, child) {
              final isDark = currentMode == ThemeMode.dark;
              return SwitchListTile(
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Karanlık Mod'),
                subtitle: Text(isDark ? 'Açık' : 'Kapalı'),
                value: isDark,
                onChanged: (val) {
                  settingsService.saveTheme(
                    val ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              );
            },
          ),
          const Divider(),

          // DİL AYARI
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
                  onChanged: (val) {
                    if (val != null) settingsService.saveLanguage(val);
                  },
                ),
              );
            },
          ),
          const Divider(),

          // HAKKINDA
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Uygulama Hakkında'),
            subtitle: const Text('Libris v1.0.0'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: const [
                      Icon(Icons.library_books),
                      SizedBox(width: 8),
                      Text('Libris'),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Sürüm: 1.0.0',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        Text('© 2023 Libris Kütüphane Yönetim Sistemi'),
                        SizedBox(height: 16),
                        Text(
                          'Lisans',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Bu yazılım GNU General Public License v3.0 (GPL-3.0) '
                          'kapsamında lisanslanmıştır.\n\n'
                          'Bu yazılımı özgürce kullanabilir, inceleyebilir, '
                          'değiştirebilir ve dağıtabilirsiniz.\n\n'
                          'Lisansın tamamı için:\n'
                          'https://www.gnu.org/licenses/gpl-3.0.html',
                        ),
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

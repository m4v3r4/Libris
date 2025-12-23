import 'package:flutter/material.dart';

import 'package:libris/features/home/screens/home_screen.dart'; // HomeScreen'i import edin
import 'package:libris/features/settings/services/settings_service.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  await DatabaseHelper.instance.database;

  // Kayıtlı temayı yükle
  final settingsService = SettingsService();
  final theme = await settingsService.getTheme();
  appThemeNotifier.value = theme;

  // Kayıtlı dili yükle
  final lang = await settingsService.getLanguage();
  appLanguageNotifier.value = lang;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Libris Kütüphane',
          themeMode: mode,
          darkTheme: ThemeData.dark(),
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

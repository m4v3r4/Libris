import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

// Tema değişikliklerini dinlemek için global bildirimci
final ValueNotifier<ThemeMode> appThemeNotifier = ValueNotifier(
  ThemeMode.system,
);

// Dil değişikliklerini dinlemek için global bildirimci
final ValueNotifier<String> appLanguageNotifier = ValueNotifier('tr');

class SettingsService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> init() async {
    final db = await _dbHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> saveTheme(ThemeMode mode) async {
    final db = await _dbHelper.database;
    await init();
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      default:
        value = 'system';
    }

    await db.insert('settings', {
      'key': 'theme_mode',
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Uygulamanın temasını güncelle
    appThemeNotifier.value = mode;
  }

  Future<ThemeMode> getTheme() async {
    final db = await _dbHelper.database;
    await init();
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['theme_mode'],
    );

    if (maps.isNotEmpty) {
      final value = maps.first['value'] as String;
      if (value == 'light') return ThemeMode.light;
      if (value == 'dark') return ThemeMode.dark;
    }
    return ThemeMode.system;
  }

  Future<void> saveLanguage(String language) async {
    final db = await _dbHelper.database;
    await init();

    await db.insert('settings', {
      'key': 'language',
      'value': language,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    appLanguageNotifier.value = language;
  }

  Future<String> getLanguage() async {
    final db = await _dbHelper.database;
    await init();
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['language'],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return 'tr';
  }
}

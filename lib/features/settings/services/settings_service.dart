import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

final ValueNotifier<ThemeMode> appThemeNotifier = ValueNotifier(
  ThemeMode.system,
);

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

  Future<void> saveValue(String key, String value) async {
    final db = await _dbHelper.database;
    await init();
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getValue(String key) async {
    final db = await _dbHelper.database;
    await init();
    final maps = await db.query(
      'settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> deleteValue(String key) async {
    final db = await _dbHelper.database;
    await init();
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }

  Future<void> saveTheme(ThemeMode mode) async {
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

    await saveValue('theme_mode', value);
    appThemeNotifier.value = mode;
  }

  Future<ThemeMode> getTheme() async {
    final value = await getValue('theme_mode');
    if (value == 'light') return ThemeMode.light;
    if (value == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> saveLanguage(String language) async {
    await saveValue('language', language);
    appLanguageNotifier.value = language;
  }

  Future<String> getLanguage() async {
    return await getValue('language') ?? 'tr';
  }
}

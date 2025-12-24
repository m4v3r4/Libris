import 'package:libris/common/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseInspectorService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Veritabanındaki tüm tablo isimlerini getirir
  Future<List<String>> getTables() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );
    return tables.map((e) => e['name'] as String).toList();
  }

  /// Bir tablonun şemasını (kolon bilgilerini) getirir
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('PRAGMA table_info($tableName)');
  }

  /// Bir tablonun tüm verilerini getirir
  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    final db = await _dbHelper.database;
    return await db.query(tableName);
  }

  /// Dinamik güncelleme
  Future<int> updateRow(
    String tableName,
    String pkColumn,
    dynamic pkValue,
    Map<String, dynamic> data,
  ) async {
    final db = await _dbHelper.database;
    return await db.update(
      tableName,
      data,
      where: '$pkColumn = ?',
      whereArgs: [pkValue],
    );
  }

  /// Dinamik silme
  Future<int> deleteRow(
    String tableName,
    String pkColumn,
    dynamic pkValue,
  ) async {
    final db = await _dbHelper.database;
    return await db.delete(
      tableName,
      where: '$pkColumn = ?',
      whereArgs: [pkValue],
    );
  }

  /// Tabloyu temizle (Truncate)
  Future<void> clearTable(String tableName) async {
    final db = await _dbHelper.database;
    await db.delete(tableName);
  }

  /// Satır Ekle (Import için)
  Future<int> insertRow(String tableName, Map<String, dynamic> row) async {
    final db = await _dbHelper.database;
    return await db.insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

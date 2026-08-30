import 'package:libris/common/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseBackupException implements Exception {
  const DatabaseBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DatabaseBackupService {
  static const String format = 'libris-backup';
  static const int formatVersion = 1;

  static const List<String> _insertOrder = <String>[
    'categories',
    'members',
    'books',
    'book_copies',
    'loans',
  ];

  static const List<String> _deleteOrder = <String>[
    'loans',
    'book_copies',
    'books',
    'members',
    'categories',
  ];

  const DatabaseBackupService();

  Future<Map<String, dynamic>> createBackup(Database db) async {
    final tables = <String, dynamic>{};
    for (final table in _insertOrder) {
      tables[table] = await db.query(table);
    }

    return <String, dynamic>{
      'format': format,
      'version': formatVersion,
      'databaseVersion': await db.getVersion(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'tables': tables,
    };
  }

  Future<void> restoreBackup(Database db, Map<String, dynamic> backup) async {
    final tables = _validateBackup(backup);

    await db.transaction((txn) async {
      for (final table in _deleteOrder) {
        await txn.delete(table);
      }

      for (final table in _insertOrder) {
        final rows = tables[table]!;
        for (final row in rows) {
          await txn.insert(
            table,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Map<String, List<Map<String, Object?>>> _validateBackup(
    Map<String, dynamic> backup,
  ) {
    if (backup['format'] != format) {
      throw const DatabaseBackupException(
        'Geçersiz veya eski Libris yedek formatı.',
      );
    }
    if (backup['version'] != formatVersion) {
      throw DatabaseBackupException(
        'Desteklenmeyen yedek sürümü: ${backup['version']}.',
      );
    }

    final databaseVersion = backup['databaseVersion'];
    if (databaseVersion is! int ||
        databaseVersion > AppDatabase.currentVersion) {
      throw DatabaseBackupException(
        'Bu yedek daha yeni bir Libris veritabanı sürümünden oluşturulmuş.',
      );
    }

    final rawTables = backup['tables'];
    if (rawTables is! Map) {
      throw const DatabaseBackupException('Yedekte tablo verisi bulunamadı.');
    }

    final result = <String, List<Map<String, Object?>>>{};
    for (final table in _insertOrder) {
      final rawRows = rawTables[table];
      if (rawRows is! List) {
        throw DatabaseBackupException('Yedekte "$table" tablosu eksik.');
      }

      final rows = <Map<String, Object?>>[];
      for (final rawRow in rawRows) {
        if (rawRow is! Map) {
          throw DatabaseBackupException(
            '"$table" tablosunda geçersiz kayıt bulundu.',
          );
        }
        rows.add(
          rawRow.map<String, Object?>(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );
      }
      result[table] = rows;
    }

    final unexpectedTables = rawTables.keys
        .map((key) => key.toString())
        .where((table) => !_insertOrder.contains(table))
        .toList();
    if (unexpectedTables.isNotEmpty) {
      throw DatabaseBackupException(
        'Yedekte desteklenmeyen tablolar var: ${unexpectedTables.join(', ')}.',
      );
    }

    return result;
  }
}

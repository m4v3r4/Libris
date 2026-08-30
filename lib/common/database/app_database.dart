import 'dart:io';

import 'package:libris/common/database/migrations/v1_to_v2.dart';
import 'package:libris/common/database/schema_v2.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const int currentVersion = 2;
  static const String fileName = 'libris.db';

  const AppDatabase._();

  static Future<Database> open() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return openAtPath(join(directory.path, fileName));
  }

  static Future<Database> openAtPath(String path, {DatabaseFactory? factory}) {
    final dbFactory = factory ?? databaseFactory;
    return dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: currentVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await createSchemaV2(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await migrateV1ToV2(db);
          }
        },
      ),
    );
  }
}

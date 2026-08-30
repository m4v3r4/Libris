import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libris/common/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late String databasePath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'libris-db-migration-',
    );
    databasePath = '${tempDirectory.path}${Platform.pathSeparator}libris.db';
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('v1 database upgrades to v2 without losing user data', () async {
    final legacyDb = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: false,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE members (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              email TEXT,
              phone TEXT,
              address TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE books (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              author TEXT NOT NULL,
              isbn TEXT,
              category TEXT,
              createdAt TEXT,
              updatedAt TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE loans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              bookId INTEGER NOT NULL,
              memberId INTEGER NOT NULL,
              loanDate TEXT NOT NULL,
              dueDate TEXT NOT NULL,
              returnedAt TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    final now = DateTime.now().toIso8601String();
    final memberId = await legacyDb.insert('members', {
      'name': 'Migration Member',
      'createdAt': now,
      'updatedAt': now,
    });
    final bookId = await legacyDb.insert('books', {
      'title': 'Migration Book',
      'author': 'Migration Author',
      'category': 'History',
      'createdAt': now,
      'updatedAt': now,
    });
    final loanId = await legacyDb.insert('loans', {
      'bookId': bookId,
      'memberId': memberId,
      'loanDate': now,
      'dueDate': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
      'createdAt': now,
      'updatedAt': now,
    });
    await legacyDb.close();

    final db = await AppDatabase.openAtPath(
      databasePath,
      factory: databaseFactoryFfi,
    );

    expect(await db.getVersion(), AppDatabase.currentVersion);

    final books = await db.query('books', where: 'id = ?', whereArgs: [bookId]);
    final members = await db.query(
      'members',
      where: 'id = ?',
      whereArgs: [memberId],
    );
    final loans = await db.query('loans', where: 'id = ?', whereArgs: [loanId]);
    final copies = await db.query(
      'book_copies',
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
    final categories = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: ['History'],
    );

    expect(books.single['title'], 'Migration Book');
    expect(books.single['publisher'], isNull);
    expect(books.single['isAvailable'], 0);
    expect(members.single['name'], 'Migration Member');
    expect(categories, hasLength(1));
    expect(books.single['categoryId'], categories.single['id']);
    expect(copies, hasLength(1));
    expect(copies.single['status'], 'loaned');
    expect(loans.single['copyId'], copies.single['id']);

    final bookColumns = await db.rawQuery('PRAGMA table_info(books)');
    final bookColumnNames = bookColumns.map((row) => row['name']).toSet();
    expect(bookColumnNames, contains('categoryId'));
    expect(bookColumnNames, isNot(contains('category')));

    final bookForeignKeys = await db.rawQuery('PRAGMA foreign_key_list(books)');
    expect(bookForeignKeys.map((row) => row['table']), contains('categories'));

    final loanForeignKeys = await db.rawQuery('PRAGMA foreign_key_list(loans)');
    expect(
      loanForeignKeys.map((row) => row['table']),
      containsAll(<String>['books', 'members']),
    );

    await db.close();
  });

  test('fresh databases are created directly at schema v2', () async {
    final db = await AppDatabase.openAtPath(
      databasePath,
      factory: databaseFactoryFfi,
    );

    expect(await db.getVersion(), AppDatabase.currentVersion);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tableNames = tables.map((row) => row['name']).toSet();
    expect(
      tableNames,
      containsAll(<String>[
        'books',
        'members',
        'loans',
        'book_copies',
        'categories',
      ]),
    );

    final bookColumns = await db.rawQuery('PRAGMA table_info(books)');
    final bookColumnNames = bookColumns.map((row) => row['name']).toSet();
    expect(bookColumnNames, contains('categoryId'));
    expect(bookColumnNames, isNot(contains('category')));

    await db.close();
  });
}

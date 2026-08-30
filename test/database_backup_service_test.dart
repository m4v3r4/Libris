import 'package:flutter_test/flutter_test.dart';
import 'package:libris/common/database/database_backup_service.dart';
import 'package:libris/common/database/schema_v2.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  const service = DatabaseBackupService();

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        singleInstance: false,
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await createSchemaV2(db);
        },
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> seedDatabase() async {
    final now = DateTime.now().toIso8601String();
    final categoryId = await database.insert('categories', {'name': 'History'});
    final memberId = await database.insert('members', {
      'name': 'Backup Member',
      'createdAt': now,
      'updatedAt': now,
    });
    final bookId = await database.insert('books', {
      'title': 'Backup Book',
      'author': 'Backup Author',
      'description': 'Backup description',
      'categoryId': categoryId,
      'isAvailable': 0,
      'createdAt': now,
      'updatedAt': now,
    });
    final copyId = await database.insert('book_copies', {
      'bookId': bookId,
      'inventoryCode': 'LBR-000001-001',
      'status': 'loaned',
      'createdAt': now,
      'updatedAt': now,
    });
    await database.insert('loans', {
      'bookId': bookId,
      'memberId': memberId,
      'copyId': copyId,
      'loanDate': now,
      'dueDate': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
      'createdAt': now,
      'updatedAt': now,
    });
  }

  test('backup -> clear database -> restore preserves related data', () async {
    await seedDatabase();
    final backup = await service.createBackup(database);

    await database.delete('loans');
    await database.delete('book_copies');
    await database.delete('books');
    await database.delete('members');
    await database.delete('categories');

    await service.restoreBackup(database, backup);

    expect(await database.query('categories'), hasLength(1));
    expect(await database.query('members'), hasLength(1));
    expect(await database.query('books'), hasLength(1));
    expect(await database.query('book_copies'), hasLength(1));
    expect(await database.query('loans'), hasLength(1));

    final book = (await database.query('books')).single;
    final category = (await database.query('categories')).single;
    final loan = (await database.query('loans')).single;
    final copy = (await database.query('book_copies')).single;

    expect(book['categoryId'], category['id']);
    expect(loan['copyId'], copy['id']);
  });

  test(
    'invalid restore rolls back and leaves existing database unchanged',
    () async {
      await seedDatabase();
      final backup = await service.createBackup(database);

      final invalid = Map<String, dynamic>.from(backup);
      final tables = Map<String, dynamic>.from(invalid['tables'] as Map);
      invalid['tables'] = tables;
      tables['book_copies'] = <Map<String, Object?>>[
        {
          'id': 1,
          'bookId': 999999,
          'inventoryCode': 'BROKEN-COPY',
          'status': 'available',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ];

      await expectLater(
        service.restoreBackup(database, invalid),
        throwsA(anything),
      );

      final books = await database.query('books');
      final members = await database.query('members');
      final copies = await database.query('book_copies');
      final loans = await database.query('loans');

      expect(books.single['title'], 'Backup Book');
      expect(members.single['name'], 'Backup Member');
      expect(copies.single['inventoryCode'], 'LBR-000001-001');
      expect(loans, hasLength(1));
    },
  );

  test('old unversioned exports are rejected before mutation', () async {
    await seedDatabase();

    await expectLater(
      service.restoreBackup(database, <String, dynamic>{'books': <dynamic>[]}),
      throwsA(isA<DatabaseBackupException>()),
    );

    expect(await database.query('books'), hasLength(1));
  });
}

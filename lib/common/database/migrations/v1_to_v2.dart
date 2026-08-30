import 'package:sqflite/sqflite.dart';

Future<void> migrateV1ToV2(Database db) async {
  await _ensureMembersTable(db);
  await _ensureLegacyBooksTable(db);
  await _ensureCategoriesTable(db);
  await _migrateBookCategories(db);
  await _ensureBookCopiesTable(db);
  await _ensureLoansTable(db);
  await _backfillPhysicalCopies(db);
}

Future<void> _ensureMembersTable(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT,
      phone TEXT,
      address TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');
}

Future<void> _ensureLegacyBooksTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS books (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      author TEXT NOT NULL,
      isbn TEXT,
      publisher TEXT,
      publishYear INTEGER,
      pageCount INTEGER,
      description TEXT,
      category TEXT,
      location TEXT,
      isAvailable INTEGER DEFAULT 1,
      createdAt TEXT,
      updatedAt TEXT
    )
  ''');

  final columns = await _columnNames(db, 'books');
  if (!columns.contains('publisher')) {
    await db.execute('ALTER TABLE books ADD COLUMN publisher TEXT');
  }
  if (!columns.contains('publishYear')) {
    await db.execute('ALTER TABLE books ADD COLUMN publishYear INTEGER');
  }
  if (!columns.contains('pageCount')) {
    await db.execute('ALTER TABLE books ADD COLUMN pageCount INTEGER');
  }
  if (!columns.contains('description')) {
    await db.execute('ALTER TABLE books ADD COLUMN description TEXT');
  }
  if (!columns.contains('location')) {
    await db.execute('ALTER TABLE books ADD COLUMN location TEXT');
  }
  if (!columns.contains('isAvailable')) {
    await db.execute(
      'ALTER TABLE books ADD COLUMN isAvailable INTEGER DEFAULT 1',
    );
  }
  if (!columns.contains('createdAt')) {
    await db.execute('ALTER TABLE books ADD COLUMN createdAt TEXT');
  }
  if (!columns.contains('updatedAt')) {
    await db.execute('ALTER TABLE books ADD COLUMN updatedAt TEXT');
  }
}

Future<void> _ensureCategoriesTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE
    )
  ''');

  final bookColumns = await _columnNames(db, 'books');
  if (!bookColumns.contains('category')) return;

  final rows = await db.rawQuery(
    "SELECT DISTINCT category FROM books WHERE category IS NOT NULL AND TRIM(category) != ''",
  );
  final batch = db.batch();
  for (final row in rows) {
    batch.insert('categories', {
      'name': row['category'],
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  await batch.commit(noResult: true);
}

Future<void> _migrateBookCategories(Database db) async {
  var columns = await _columnNames(db, 'books');
  if (!columns.contains('categoryId')) {
    await db.execute('''
      ALTER TABLE books
      ADD COLUMN categoryId INTEGER REFERENCES categories(id)
      ON UPDATE CASCADE ON DELETE RESTRICT
    ''');
    columns = await _columnNames(db, 'books');
  }

  if (columns.contains('category')) {
    await db.execute('''
      UPDATE books
      SET categoryId = (
        SELECT id FROM categories c WHERE c.name = books.category
      )
      WHERE category IS NOT NULL AND TRIM(category) != ''
    ''');
    await db.execute('ALTER TABLE books DROP COLUMN category');
  }

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_books_categoryId ON books(categoryId)',
  );
}

Future<void> _ensureBookCopiesTable(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS book_copies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bookId INTEGER NOT NULL,
      inventoryCode TEXT NOT NULL UNIQUE,
      status TEXT NOT NULL DEFAULT 'available',
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (bookId) REFERENCES books(id) ON UPDATE CASCADE ON DELETE RESTRICT
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_book_copies_bookId ON book_copies(bookId)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_book_copies_status ON book_copies(status)',
  );
}

Future<void> _ensureLoansTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS loans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bookId INTEGER NOT NULL,
      memberId INTEGER NOT NULL,
      copyId INTEGER,
      loanDate TEXT NOT NULL,
      dueDate TEXT NOT NULL,
      returnedAt TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (bookId) REFERENCES books(id) ON UPDATE CASCADE ON DELETE RESTRICT,
      FOREIGN KEY (memberId) REFERENCES members(id) ON UPDATE CASCADE ON DELETE RESTRICT
    )
  ''');

  final columns = await _columnNames(db, 'loans');
  if (!columns.contains('copyId')) {
    await db.execute('ALTER TABLE loans ADD COLUMN copyId INTEGER');
  }

  final foreignKeys = await db.rawQuery('PRAGMA foreign_key_list(loans)');
  if (foreignKeys.isEmpty) {
    await db.execute('ALTER TABLE loans RENAME TO loans_v1');
    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        memberId INTEGER NOT NULL,
        copyId INTEGER,
        loanDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        returnedAt TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books(id) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY (memberId) REFERENCES members(id) ON UPDATE CASCADE ON DELETE RESTRICT
      )
    ''');
    await db.execute('''
      INSERT INTO loans (
        id, bookId, memberId, copyId, loanDate, dueDate, returnedAt, createdAt, updatedAt
      )
      SELECT
        id, bookId, memberId, copyId, loanDate, dueDate, returnedAt, createdAt, updatedAt
      FROM loans_v1
    ''');
    await db.execute('DROP TABLE loans_v1');
  }

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_loans_copyId ON loans(copyId)',
  );
}

Future<void> _backfillPhysicalCopies(Database db) async {
  final books = await db.query('books', columns: ['id']);
  for (final book in books) {
    final bookId = book['id'] as int;
    final existing = await db.query(
      'book_copies',
      columns: ['id'],
      where: 'bookId = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (existing.isNotEmpty) continue;

    final now = DateTime.now().toIso8601String();
    await db.insert('book_copies', {
      'bookId': bookId,
      'inventoryCode': await _nextInventoryCode(db, bookId),
      'status': 'available',
      'createdAt': now,
      'updatedAt': now,
    });
  }

  final legacyLoans = await db.query(
    'loans',
    columns: ['id', 'bookId', 'returnedAt'],
    where: 'copyId IS NULL',
    orderBy: 'loanDate ASC',
  );
  for (final loan in legacyLoans) {
    final bookId = loan['bookId'] as int;
    final active = loan['returnedAt'] == null;
    final copies = await db.query(
      'book_copies',
      columns: ['id'],
      where: active ? 'bookId = ? AND status = ?' : 'bookId = ?',
      whereArgs: active ? [bookId, 'available'] : [bookId],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (copies.isEmpty) continue;

    final copyId = copies.first['id'] as int;
    await db.update(
      'loans',
      {'copyId': copyId},
      where: 'id = ?',
      whereArgs: [loan['id']],
    );
    if (active) {
      await db.update(
        'book_copies',
        {'status': 'loaned', 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [copyId],
      );
    }
  }

  final activeLoans = await db.query(
    'loans',
    columns: ['copyId'],
    where: 'returnedAt IS NULL AND copyId IS NOT NULL',
  );
  for (final loan in activeLoans) {
    await db.update(
      'book_copies',
      {'status': 'loaned', 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [loan['copyId']],
    );
  }

  for (final book in books) {
    await _syncBookAvailability(db, book['id'] as int);
  }
}

Future<Set<String>> _columnNames(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((row) => row['name'] as String).toSet();
}

Future<String> _nextInventoryCode(DatabaseExecutor db, int bookId) async {
  final count =
      Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM book_copies WHERE bookId = ?', [
          bookId,
        ]),
      ) ??
      0;
  var sequence = count + 1;
  final bookPart = bookId.toString().padLeft(6, '0');
  while (true) {
    final code = 'LBR-$bookPart-${sequence.toString().padLeft(3, '0')}';
    final existing = await db.query(
      'book_copies',
      columns: ['id'],
      where: 'inventoryCode = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (existing.isEmpty) return code;
    sequence++;
  }
}

Future<void> _syncBookAvailability(DatabaseExecutor db, int bookId) async {
  final available =
      Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM book_copies WHERE bookId = ? AND status = ?',
          [bookId, 'available'],
        ),
      ) ??
      0;
  await db.update(
    'books',
    {
      'isAvailable': available > 0 ? 1 : 0,
      'updatedAt': DateTime.now().toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [bookId],
  );
}

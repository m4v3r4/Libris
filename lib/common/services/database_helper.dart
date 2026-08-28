import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/common/models/member.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:libris/features/books/models/book_copy.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Database? _database;

  DatabaseHelper._privateConstructor();

  @visibleForTesting
  DatabaseHelper.forTesting(Database database) : _database = database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDb();
    return _database!;
  }

  Future<Database> _openDb() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String path = join(dir.path, 'libris.db');

    final db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    await _initializeSchema(db);
    return db;
  }

  Future<void> _initializeSchema(Database db) async {
    await _ensureMembersTable(db);
    await _ensureBooksTable(db);
    await _ensureBookCopiesTableStructure(db);
    await _ensureLoansTable(db);
    await _backfillBookCopies(db);
    await _ensureCategoriesTable(db);
  }

  @visibleForTesting
  Future<void> initializeSchemaForTesting() async {
    await _initializeSchema(await database);
  }

  // --- CATEGORIES ---

  /// Kategoriler tablosunu oluşturur ve varsa kitaplardan veri aktarır.
  Future<void> _ensureCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories'),
    );
    if (count == 0) {
      try {
        final result = await db.rawQuery(
          "SELECT DISTINCT category FROM books WHERE category IS NOT NULL AND category != ''",
        );

        final batch = db.batch();
        for (final row in result) {
          batch.insert('categories', {
            'name': row['category'],
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
      } catch (e) {
        debugPrint('Migration uyarısı: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCategoriesWithStats() async {
    final db = await database;
    return db.rawQuery('''
      SELECT c.id, c.name,
      (SELECT COUNT(*) FROM books b WHERE b.category = c.name) as book_count
      FROM categories c
      ORDER BY c.name ASC
    ''');
  }

  Future<List<String>> getCategoryNames() async {
    final db = await database;
    final result = await db.query(
      'categories',
      columns: ['name'],
      orderBy: 'name ASC',
    );
    return result.map((e) => e['name'] as String).toList();
  }

  Future<int> addCategory(String name) async {
    final db = await database;
    return db.insert('categories', {'name': name});
  }

  Future<int> updateCategory(int id, String newName) async {
    final db = await database;
    await db.transaction((txn) async {
      final oldNameMap = await txn.query(
        'categories',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [id],
      );
      if (oldNameMap.isNotEmpty) {
        final oldName = oldNameMap.first['name'] as String;
        await txn.update(
          'books',
          {'category': newName},
          where: 'category = ?',
          whereArgs: [oldName],
        );
      }
      await txn.update(
        'categories',
        {'name': newName},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    return id;
  }

  Future<void> deleteCategory(int id, String name) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM books WHERE category = ?', [name]),
    );
    if (count != null && count > 0) {
      throw Exception(
        'Bu kategoriye ait $count adet kitap var. Önce kitapların kategorisini değiştirin.',
      );
    }
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- MEMBERS ---

  Future<void> _ensureMembersTable(Database db) async {
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

  Future<int> insertMember(Member member) async {
    final db = await database;
    return db.insert(
      'members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Member>> getMembers() async {
    final db = await database;
    final maps = await db.query('members', orderBy: 'createdAt DESC');
    return maps.map(Member.fromMap).toList();
  }

  Future<Member?> getMemberById(int id) async {
    final db = await database;
    final maps = await db.query(
      'members',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Member.fromMap(maps.first) : null;
  }

  Future<int> updateMember(Member member) async {
    final db = await database;
    return db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    final loanCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM loans WHERE memberId = ?', [id]),
    );
    if ((loanCount ?? 0) > 0) {
      throw Exception(
        'Bu üyenin emanet geçmişi olduğu için silinemez. Önce emanet kayıtlarını temizleyin.',
      );
    }
    return db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Member>> searchMembers(String query) async {
    final db = await database;
    final maps = await db.query(
      'members',
      where: 'name LIKE ? OR email LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map(Member.fromMap).toList();
  }

  Future<List<Member>> getTopMembers({int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT m.*, COUNT(l.id) as loan_count
      FROM members m
      JOIN loans l ON m.id = l.memberId
      GROUP BY m.id
      ORDER BY loan_count DESC
      LIMIT ?
    ''',
      [limit],
    );
    return maps.map(Member.fromMap).toList();
  }

  Future<List<Member>> getLatestMembers({int limit = 5}) async {
    final db = await database;
    final maps = await db.query('members', orderBy: 'id DESC', limit: limit);
    return maps.map(Member.fromMap).toList();
  }

  // --- BOOK COPIES ---

  Future<void> _ensureBookCopiesTableStructure(Database db) async {
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

  Future<String> _generateInventoryCode(
    DatabaseExecutor executor,
    int bookId,
  ) async {
    final count = Sqflite.firstIntValue(
          await executor.rawQuery(
            'SELECT COUNT(*) FROM book_copies WHERE bookId = ?',
            [bookId],
          ),
        ) ??
        0;

    var sequence = count + 1;
    final bookPart = bookId.toString().padLeft(6, '0');
    while (true) {
      final code = 'LBR-$bookPart-${sequence.toString().padLeft(3, '0')}';
      final existing = await executor.query(
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

  Future<void> _backfillBookCopies(Database db) async {
    await db.transaction((txn) async {
      final books = await txn.query('books', columns: ['id']);

      for (final book in books) {
        final bookId = book['id'] as int;
        final copies = await txn.query(
          'book_copies',
          columns: ['id'],
          where: 'bookId = ?',
          whereArgs: [bookId],
          limit: 1,
        );

        if (copies.isEmpty) {
          final now = DateTime.now().toIso8601String();
          await txn.insert('book_copies', {
            'bookId': bookId,
            'inventoryCode': await _generateInventoryCode(txn, bookId),
            'status': BookCopyStatus.available.name,
            'createdAt': now,
            'updatedAt': now,
          });
        }
      }

      final legacyLoans = await txn.query(
        'loans',
        columns: ['id', 'bookId', 'returnedAt'],
        where: 'copyId IS NULL',
        orderBy: 'loanDate ASC',
      );

      for (final loan in legacyLoans) {
        final loanId = loan['id'] as int;
        final bookId = loan['bookId'] as int;
        final isActive = loan['returnedAt'] == null;

        List<Map<String, Object?>> copies;
        if (isActive) {
          copies = await txn.query(
            'book_copies',
            columns: ['id'],
            where: 'bookId = ? AND status = ?',
            whereArgs: [bookId, BookCopyStatus.available.name],
            orderBy: 'id ASC',
            limit: 1,
          );
        } else {
          copies = await txn.query(
            'book_copies',
            columns: ['id'],
            where: 'bookId = ?',
            whereArgs: [bookId],
            orderBy: 'id ASC',
            limit: 1,
          );
        }

        if (copies.isEmpty) continue;
        final copyId = copies.first['id'] as int;
        await txn.update(
          'loans',
          {'copyId': copyId},
          where: 'id = ?',
          whereArgs: [loanId],
        );

        if (isActive) {
          await txn.update(
            'book_copies',
            {
              'status': BookCopyStatus.loaned.name,
              'updatedAt': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [copyId],
          );
        }
      }

      final activeLoans = await txn.query(
        'loans',
        columns: ['copyId'],
        where: 'returnedAt IS NULL AND copyId IS NOT NULL',
      );
      for (final loan in activeLoans) {
        await txn.update(
          'book_copies',
          {
            'status': BookCopyStatus.loaned.name,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [loan['copyId']],
        );
      }

      for (final book in books) {
        await _syncBookAvailability(txn, book['id'] as int);
      }
    });
  }

  Future<void> _syncBookAvailability(
    DatabaseExecutor executor,
    int bookId,
  ) async {
    final availableCount = Sqflite.firstIntValue(
          await executor.rawQuery(
            'SELECT COUNT(*) FROM book_copies WHERE bookId = ? AND status = ?',
            [bookId, BookCopyStatus.available.name],
          ),
        ) ??
        0;

    await executor.update(
      'books',
      {
        'isAvailable': availableCount > 0 ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<List<BookCopy>> getBookCopies(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'book_copies',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'id ASC',
    );
    return maps.map(BookCopy.fromMap).toList();
  }

  Future<List<BookCopy>> getAvailableBookCopies(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'book_copies',
      where: 'bookId = ? AND status = ?',
      whereArgs: [bookId, BookCopyStatus.available.name],
      orderBy: 'id ASC',
    );
    return maps.map(BookCopy.fromMap).toList();
  }

  Future<BookCopy?> getBookCopyById(int id) async {
    final db = await database;
    final maps = await db.query(
      'book_copies',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : BookCopy.fromMap(maps.first);
  }

  Future<Map<String, int>> getBookCopyStats(int bookId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN status = 'available' THEN 1 ELSE 0 END) AS available,
        SUM(CASE WHEN status = 'loaned' THEN 1 ELSE 0 END) AS loaned,
        SUM(CASE WHEN status = 'lost' THEN 1 ELSE 0 END) AS lost,
        SUM(CASE WHEN status = 'maintenance' THEN 1 ELSE 0 END) AS maintenance
      FROM book_copies
      WHERE bookId = ?
      ''',
      [bookId],
    );
    final row = rows.first;
    return {
      'total': (row['total'] as int?) ?? 0,
      'available': (row['available'] as int?) ?? 0,
      'loaned': (row['loaned'] as int?) ?? 0,
      'lost': (row['lost'] as int?) ?? 0,
      'maintenance': (row['maintenance'] as int?) ?? 0,
    };
  }

  Future<int> createBookCopy(
    int bookId, {
    String? inventoryCode,
    BookCopyStatus status = BookCopyStatus.available,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final book = await txn.query(
        'books',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [bookId],
        limit: 1,
      );
      if (book.isEmpty) {
        throw Exception('Kitap kaydı bulunamadı.');
      }

      final now = DateTime.now().toIso8601String();
      final code = inventoryCode?.trim().isNotEmpty == true
          ? inventoryCode!.trim()
          : await _generateInventoryCode(txn, bookId);

      final id = await txn.insert('book_copies', {
        'bookId': bookId,
        'inventoryCode': code,
        'status': status.name,
        'createdAt': now,
        'updatedAt': now,
      });
      await _syncBookAvailability(txn, bookId);
      return id;
    });
  }

  Future<int> updateBookCopyStatus(
    int copyId,
    BookCopyStatus status,
  ) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'book_copies',
        columns: ['bookId', 'status'],
        where: 'id = ?',
        whereArgs: [copyId],
        limit: 1,
      );
      if (rows.isEmpty) return 0;

      final bookId = rows.first['bookId'] as int;
      final activeLoanCount = Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM loans WHERE copyId = ? AND returnedAt IS NULL',
              [copyId],
            ),
          ) ??
          0;

      if (activeLoanCount > 0) {
        throw Exception(
          'Emanetteki bir nüshanın durumu iade alınmadan değiştirilemez.',
        );
      }
      if (status == BookCopyStatus.loaned) {
        throw Exception(
          'Emanette durumu yalnızca emanet işlemi sırasında atanabilir.',
        );
      }

      final count = await txn.update(
        'book_copies',
        {
          'status': status.name,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [copyId],
      );
      await _syncBookAvailability(txn, bookId);
      return count;
    });
  }

  Future<int> deleteBookCopy(int copyId) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'book_copies',
        columns: ['bookId'],
        where: 'id = ?',
        whereArgs: [copyId],
        limit: 1,
      );
      if (rows.isEmpty) return 0;

      final loanCount = Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM loans WHERE copyId = ?',
              [copyId],
            ),
          ) ??
          0;
      if (loanCount > 0) {
        throw Exception(
          'Bu nüshanın emanet geçmişi olduğu için silinemez.',
        );
      }

      final bookId = rows.first['bookId'] as int;
      final count = await txn.delete(
        'book_copies',
        where: 'id = ?',
        whereArgs: [copyId],
      );
      await _syncBookAvailability(txn, bookId);
      return count;
    });
  }

  // --- LOANS ---

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

    final tableInfo = await db.rawQuery('PRAGMA table_info(loans)');
    final columns = tableInfo.map((c) => c['name'] as String).toList();
    if (!columns.contains('copyId')) {
      await db.execute('ALTER TABLE loans ADD COLUMN copyId INTEGER');
    }

    await _ensureLoansForeignKeys(db);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loans_copyId ON loans(copyId)',
    );
  }

  Future<void> _ensureLoansForeignKeys(Database db) async {
    final fkRows = await db.rawQuery('PRAGMA foreign_key_list(loans)');
    if (fkRows.isNotEmpty) return;

    await db.transaction((txn) async {
      await txn.execute('ALTER TABLE loans RENAME TO loans_old');
      await txn.execute('''
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
      await txn.execute('''
        INSERT INTO loans (id, bookId, memberId, copyId, loanDate, dueDate, returnedAt, createdAt, updatedAt)
        SELECT id, bookId, memberId, copyId, loanDate, dueDate, returnedAt, createdAt, updatedAt
        FROM loans_old
      ''');
      await txn.execute('DROP TABLE loans_old');
    });
  }

  Future<int> createLoan(Loan loan) async {
    final db = await database;
    return db.transaction((txn) async {
      Map<String, Object?>? copyRow;

      if (loan.copyId != null) {
        final rows = await txn.query(
          'book_copies',
          columns: ['id', 'bookId', 'status'],
          where: 'id = ?',
          whereArgs: [loan.copyId],
          limit: 1,
        );
        if (rows.isNotEmpty) copyRow = rows.first;
      } else {
        final rows = await txn.query(
          'book_copies',
          columns: ['id', 'bookId', 'status'],
          where: 'bookId = ? AND status = ?',
          whereArgs: [loan.bookId, BookCopyStatus.available.name],
          orderBy: 'id ASC',
          limit: 1,
        );
        if (rows.isNotEmpty) copyRow = rows.first;
      }

      if (copyRow == null || copyRow['bookId'] != loan.bookId) {
        throw Exception('Seçilen kitaba ait geçerli bir nüsha bulunamadı.');
      }
      if (copyRow['status'] != BookCopyStatus.available.name) {
        throw Exception('Seçilen nüsha şu anda müsait değil.');
      }

      final copyId = copyRow['id'] as int;
      final loanMap = loan.toMap()..['copyId'] = copyId;
      final id = await txn.insert('loans', loanMap);

      await txn.update(
        'book_copies',
        {
          'status': BookCopyStatus.loaned.name,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [copyId],
      );
      await _syncBookAvailability(txn, loan.bookId);
      return id;
    });
  }

  Future<int> updateLoan(Loan loan) async {
    final db = await database;
    return db.transaction((txn) async {
      if (loan.id == null) return 0;

      final existingRows = await txn.query(
        'loans',
        where: 'id = ?',
        whereArgs: [loan.id],
        limit: 1,
      );
      if (existingRows.isEmpty) return 0;

      final existing = existingRows.first;
      final existingBookId = existing['bookId'] as int;
      final existingCopyId = existing['copyId'] as int?;
      final wasActive = existing['returnedAt'] == null;
      final targetCopyId = loan.copyId ?? existingCopyId;

      if (wasActive &&
          (loan.bookId != existingBookId || targetCopyId != existingCopyId)) {
        throw Exception(
          'Aktif bir emanetin kitabı veya nüshası değiştirilemez. Önce iade alın.',
        );
      }

      final loanMap = loan.toMap()..['copyId'] = targetCopyId;
      final result = await txn.update(
        'loans',
        loanMap,
        where: 'id = ?',
        whereArgs: [loan.id],
      );

      if (wasActive && loan.returnedAt != null && existingCopyId != null) {
        await txn.update(
          'book_copies',
          {
            'status': BookCopyStatus.available.name,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existingCopyId],
        );
        await _syncBookAvailability(txn, existingBookId);
      }

      return result;
    });
  }

  Future<List<Loan>> getLoans() async {
    final db = await database;
    final maps = await db.query('loans', orderBy: 'loanDate DESC');
    return maps.map(Loan.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getActiveLoans() async {
    final db = await database;
    return db.rawQuery('''
      SELECT l.*, b.title as bookTitle, m.name as memberName,
             c.inventoryCode as inventoryCode
      FROM loans l
      LEFT JOIN books b ON l.bookId = b.id
      LEFT JOIN members m ON l.memberId = m.id
      LEFT JOIN book_copies c ON l.copyId = c.id
      WHERE l.returnedAt IS NULL
      ORDER BY l.dueDate ASC
    ''');
  }

  Future<List<Loan>> getLoansByMember(int memberId) async {
    final db = await database;
    final maps = await db.query(
      'loans',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'loanDate DESC',
    );
    return maps.map(Loan.fromMap).toList();
  }

  Future<List<Loan>> getLoansByBook(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'loans',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'loanDate DESC',
    );
    return maps.map(Loan.fromMap).toList();
  }

  Future<int> returnLoan(int loanId) async {
    final db = await database;
    return db.transaction((txn) async {
      final loanMaps = await txn.query(
        'loans',
        columns: ['bookId', 'copyId', 'returnedAt'],
        where: 'id = ?',
        whereArgs: [loanId],
        limit: 1,
      );
      if (loanMaps.isEmpty) return 0;
      if (loanMaps.first['returnedAt'] != null) return 0;

      final bookId = loanMaps.first['bookId'] as int;
      final copyId = loanMaps.first['copyId'] as int?;
      final now = DateTime.now().toIso8601String();
      final result = await txn.update(
        'loans',
        {'returnedAt': now, 'updatedAt': now},
        where: 'id = ?',
        whereArgs: [loanId],
      );

      if (result > 0 && copyId != null) {
        await txn.update(
          'book_copies',
          {'status': BookCopyStatus.available.name, 'updatedAt': now},
          where: 'id = ?',
          whereArgs: [copyId],
        );
      }
      if (result > 0) {
        await _syncBookAvailability(txn, bookId);
      }
      return result;
    });
  }

  Future<List<Map<String, dynamic>>> getOverdueLoans() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.rawQuery(
      '''
      SELECT l.*, b.title as bookTitle, m.name as memberName,
             c.inventoryCode as inventoryCode
      FROM loans l
      LEFT JOIN books b ON l.bookId = b.id
      LEFT JOIN members m ON l.memberId = m.id
      LEFT JOIN book_copies c ON l.copyId = c.id
      WHERE l.returnedAt IS NULL AND l.dueDate < ?
      ORDER BY l.dueDate ASC
    ''',
      [now],
    );
  }

  Future<List<Map<String, dynamic>>> getRecentLoans({int limit = 10}) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT l.*, b.title as bookTitle, m.name as memberName,
             c.inventoryCode as inventoryCode
      FROM loans l
      LEFT JOIN books b ON l.bookId = b.id
      LEFT JOIN members m ON l.memberId = m.id
      LEFT JOIN book_copies c ON l.copyId = c.id
      ORDER BY l.updatedAt DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<int> deleteLoan(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      final loanMaps = await txn.query(
        'loans',
        columns: ['bookId', 'copyId', 'returnedAt'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (loanMaps.isEmpty) return 0;

      final loan = loanMaps.first;
      final bookId = loan['bookId'] as int;
      final copyId = loan['copyId'] as int?;
      final wasActive = loan['returnedAt'] == null;
      final result = await txn.delete('loans', where: 'id = ?', whereArgs: [id]);

      if (result > 0 && wasActive && copyId != null) {
        await txn.update(
          'book_copies',
          {
            'status': BookCopyStatus.available.name,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [copyId],
        );
      }
      if (result > 0) {
        await _syncBookAvailability(txn, bookId);
      }
      return result;
    });
  }

  // --- BOOKS ---

  Future<void> _ensureBooksTable(Database db) async {
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

    final tableInfo = await db.rawQuery('PRAGMA table_info(books)');
    final columns = tableInfo.map((c) => c['name'] as String).toList();

    if (!columns.contains('category')) {
      await db.execute('ALTER TABLE books ADD COLUMN category TEXT');
    }
    if (!columns.contains('publisher')) {
      await db.execute('ALTER TABLE books ADD COLUMN publisher TEXT');
    }
    if (!columns.contains('publishYear')) {
      await db.execute('ALTER TABLE books ADD COLUMN publishYear INTEGER');
    }
    if (!columns.contains('location')) {
      await db.execute('ALTER TABLE books ADD COLUMN location TEXT');
    }
    if (!columns.contains('isAvailable')) {
      await db.execute(
        'ALTER TABLE books ADD COLUMN isAvailable INTEGER DEFAULT 1',
      );
    }
  }

  Future<int> createBook(Book book) async {
    final db = await database;
    return db.transaction((txn) async {
      final bookMap = book.toMap()..remove('id');
      final bookId = await txn.insert('books', bookMap);
      final now = DateTime.now().toIso8601String();
      await txn.insert('book_copies', {
        'bookId': bookId,
        'inventoryCode': await _generateInventoryCode(txn, bookId),
        'status': BookCopyStatus.available.name,
        'createdAt': now,
        'updatedAt': now,
      });
      await _syncBookAvailability(txn, bookId);
      return bookId;
    });
  }

  Future<List<Book>> getBooks() async {
    final db = await database;
    final maps = await db.query('books', orderBy: 'title ASC');
    return maps.map(Book.fromMap).toList();
  }

  Future<List<Book>> getBooksByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'books',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'title ASC',
    );
    return maps.map(Book.fromMap).toList();
  }

  Future<int> updateBookCategory(int bookId, String newCategory) async {
    final db = await database;
    return db.update(
      'books',
      {'category': newCategory, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<Book?> getBookById(int id) async {
    final db = await database;
    final maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Book.fromMap(maps.first) : null;
  }

  Future<int> updateBook(Book book) async {
    final db = await database;
    return db.transaction((txn) async {
      final map = book.toMap();
      final count = await txn.update(
        'books',
        map,
        where: 'id = ?',
        whereArgs: [book.id],
      );
      if (book.id != null) {
        await _syncBookAvailability(txn, book.id!);
      }
      return count;
    });
  }

  Future<int> deleteBook(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      final loanCount = Sqflite.firstIntValue(
            await txn.rawQuery('SELECT COUNT(*) FROM loans WHERE bookId = ?', [id]),
          ) ??
          0;
      if (loanCount > 0) {
        throw Exception(
          'Bu kitabın emanet geçmişi olduğu için silinemez. Önce emanet kayıtlarını temizleyin.',
        );
      }

      await txn.delete('book_copies', where: 'bookId = ?', whereArgs: [id]);
      return txn.delete('books', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Book>> getTopBooks({int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT b.*, COUNT(l.id) as loan_count
      FROM books b
      JOIN loans l ON b.id = l.bookId
      GROUP BY b.id
      ORDER BY loan_count DESC
      LIMIT ?
    ''',
      [limit],
    );

    return maps.map(Book.fromMap).toList();
  }

  Future<List<Book>> getLatestBooks({int limit = 5}) async {
    final db = await database;
    final maps = await db.query('books', orderBy: 'id DESC', limit: limit);
    return maps.map(Book.fromMap).toList();
  }
}

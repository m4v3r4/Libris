import 'package:libris/features/books/models/book.dart';
import 'package:libris/features/books/models/book_copy.dart';
import 'package:libris/features/categories/data/category_repository.dart';
import 'package:sqflite/sqflite.dart';

class BookRepository {
  BookRepository(this._database, this._categories);

  final DatabaseGetter _database;
  final CategoryRepository _categories;

  Future<String> generateInventoryCode(
    DatabaseExecutor executor,
    int bookId,
  ) async {
    final count =
        Sqflite.firstIntValue(
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

  Future<void> syncAvailability(
    DatabaseExecutor executor,
    int bookId,
  ) async {
    final availableCount =
        Sqflite.firstIntValue(
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

  Future<List<BookCopy>> getCopies(int bookId) async {
    final db = await _database();
    final maps = await db.query(
      'book_copies',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'id ASC',
    );
    return maps.map(BookCopy.fromMap).toList();
  }

  Future<List<BookCopy>> getAvailableCopies(int bookId) async {
    final db = await _database();
    final maps = await db.query(
      'book_copies',
      where: 'bookId = ? AND status = ?',
      whereArgs: [bookId, BookCopyStatus.available.name],
      orderBy: 'id ASC',
    );
    return maps.map(BookCopy.fromMap).toList();
  }

  Future<BookCopy?> getCopyById(int id) async {
    final db = await _database();
    final maps = await db.query(
      'book_copies',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : BookCopy.fromMap(maps.first);
  }

  Future<Map<String, int>> getCopyStats(int bookId) async {
    final db = await _database();
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

  Future<int> createCopy(
    int bookId, {
    String? inventoryCode,
    BookCopyStatus status = BookCopyStatus.available,
  }) async {
    final db = await _database();
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
          : await generateInventoryCode(txn, bookId);

      final id = await txn.insert('book_copies', {
        'bookId': bookId,
        'inventoryCode': code,
        'status': status.name,
        'createdAt': now,
        'updatedAt': now,
      });
      await syncAvailability(txn, bookId);
      return id;
    });
  }

  Future<int> updateCopyStatus(int copyId, BookCopyStatus status) async {
    final db = await _database();
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
      final activeLoanCount =
          Sqflite.firstIntValue(
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
        {'status': status.name, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [copyId],
      );
      await syncAvailability(txn, bookId);
      return count;
    });
  }

  Future<int> deleteCopy(int copyId) async {
    final db = await _database();
    return db.transaction((txn) async {
      final rows = await txn.query(
        'book_copies',
        columns: ['bookId'],
        where: 'id = ?',
        whereArgs: [copyId],
        limit: 1,
      );
      if (rows.isEmpty) return 0;

      final loanCount =
          Sqflite.firstIntValue(
            await txn.rawQuery('SELECT COUNT(*) FROM loans WHERE copyId = ?', [
              copyId,
            ]),
          ) ??
          0;
      if (loanCount > 0) {
        throw Exception('Bu nüshanın emanet geçmişi olduğu için silinemez.');
      }

      final bookId = rows.first['bookId'] as int;
      final count = await txn.delete(
        'book_copies',
        where: 'id = ?',
        whereArgs: [copyId],
      );
      await syncAvailability(txn, bookId);
      return count;
    });
  }

  Future<int> create(Book book) async {
    final db = await _database();
    return db.transaction((txn) async {
      final bookMap = book.toMap()
        ..remove('id')
        ..remove('category');
      bookMap['categoryId'] = await _categories.resolveCategoryId(
        txn,
        book.category,
      );
      final bookId = await txn.insert('books', bookMap);
      final now = DateTime.now().toIso8601String();
      await txn.insert('book_copies', {
        'bookId': bookId,
        'inventoryCode': await generateInventoryCode(txn, bookId),
        'status': BookCopyStatus.available.name,
        'createdAt': now,
        'updatedAt': now,
      });
      await syncAvailability(txn, bookId);
      return bookId;
    });
  }

  Future<List<Book>> getAll() async {
    final db = await _database();
    final maps = await db.rawQuery('''
      SELECT b.*, c.name AS category
      FROM books b
      LEFT JOIN categories c ON b.categoryId = c.id
      ORDER BY b.title ASC
    ''');
    return maps.map(Book.fromMap).toList();
  }

  Future<List<Book>> getByCategory(String category) async {
    final db = await _database();
    final maps = await db.rawQuery(
      '''
      SELECT b.*, c.name AS category
      FROM books b
      JOIN categories c ON b.categoryId = c.id
      WHERE c.name = ?
      ORDER BY b.title ASC
      ''',
      [category],
    );
    return maps.map(Book.fromMap).toList();
  }

  Future<int> updateCategory(int bookId, String newCategory) async {
    final db = await _database();
    return db.transaction((txn) async {
      final categoryId = await _categories.resolveCategoryId(txn, newCategory);
      return txn.update(
        'books',
        {
          'categoryId': categoryId,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [bookId],
      );
    });
  }

  Future<Book?> getById(int id) async {
    final db = await _database();
    final maps = await db.rawQuery(
      '''
      SELECT b.*, c.name AS category
      FROM books b
      LEFT JOIN categories c ON b.categoryId = c.id
      WHERE b.id = ?
      LIMIT 1
      ''',
      [id],
    );
    return maps.isNotEmpty ? Book.fromMap(maps.first) : null;
  }

  Future<int> update(Book book) async {
    final db = await _database();
    return db.transaction((txn) async {
      final map = book.toMap()..remove('category');
      map['categoryId'] = await _categories.resolveCategoryId(
        txn,
        book.category,
      );
      final count = await txn.update(
        'books',
        map,
        where: 'id = ?',
        whereArgs: [book.id],
      );
      if (book.id != null) {
        await syncAvailability(txn, book.id!);
      }
      return count;
    });
  }

  Future<int> delete(int id) async {
    final db = await _database();
    return db.transaction((txn) async {
      final loanCount =
          Sqflite.firstIntValue(
            await txn.rawQuery('SELECT COUNT(*) FROM loans WHERE bookId = ?', [
              id,
            ]),
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

  Future<List<Book>> getTop({int limit = 5}) async {
    final db = await _database();
    final maps = await db.rawQuery(
      '''
      SELECT b.*, c.name AS category, COUNT(l.id) as loan_count
      FROM books b
      JOIN loans l ON b.id = l.bookId
      LEFT JOIN categories c ON b.categoryId = c.id
      GROUP BY b.id
      ORDER BY loan_count DESC
      LIMIT ?
      ''',
      [limit],
    );
    return maps.map(Book.fromMap).toList();
  }

  Future<List<Book>> getLatest({int limit = 5}) async {
    final db = await _database();
    final maps = await db.rawQuery(
      '''
      SELECT b.*, c.name AS category
      FROM books b
      LEFT JOIN categories c ON b.categoryId = c.id
      ORDER BY b.id DESC
      LIMIT ?
      ''',
      [limit],
    );
    return maps.map(Book.fromMap).toList();
  }
}

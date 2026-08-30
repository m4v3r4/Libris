import 'package:libris/common/models/loan.dart';
import 'package:libris/features/books/data/book_repository.dart';
import 'package:libris/features/books/models/book_copy.dart';
import 'package:libris/features/categories/data/category_repository.dart';

class LoanRepository {
  LoanRepository(this._database, this._books);

  final DatabaseGetter _database;
  final BookRepository _books;

  Future<int> create(Loan loan) async {
    final db = await _database();
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
      await _books.syncAvailability(txn, loan.bookId);
      return id;
    });
  }

  Future<int> update(Loan loan) async {
    final db = await _database();
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
        await _books.syncAvailability(txn, existingBookId);
      }

      return result;
    });
  }

  Future<List<Loan>> getAll() async {
    final db = await _database();
    final maps = await db.query('loans', orderBy: 'loanDate DESC');
    return maps.map(Loan.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getActive() async {
    final db = await _database();
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

  Future<List<Loan>> getByMember(int memberId) async {
    final db = await _database();
    final maps = await db.query(
      'loans',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'loanDate DESC',
    );
    return maps.map(Loan.fromMap).toList();
  }

  Future<List<Loan>> getByBook(int bookId) async {
    final db = await _database();
    final maps = await db.query(
      'loans',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'loanDate DESC',
    );
    return maps.map(Loan.fromMap).toList();
  }

  Future<int> returnLoan(int loanId) async {
    final db = await _database();
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
        await _books.syncAvailability(txn, bookId);
      }
      return result;
    });
  }

  Future<List<Map<String, dynamic>>> getOverdue() async {
    final db = await _database();
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

  Future<List<Map<String, dynamic>>> getRecent({int limit = 10}) async {
    final db = await _database();
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

  Future<int> delete(int id) async {
    final db = await _database();
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
      final result = await txn.delete(
        'loans',
        where: 'id = ?',
        whereArgs: [id],
      );

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
        await _books.syncAvailability(txn, bookId);
      }
      return result;
    });
  }
}

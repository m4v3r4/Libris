import 'package:sqflite/sqflite.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/loans/models/loan.dart';

class LoanService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// tabloyu garanti altına al
  Future<void> _ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS loans (
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
  }

  Future<Database> _db() async {
    final db = await _dbHelper.database;
    await _ensureTable(db);
    return db;
  }

  /// Yeni emanet oluştur
  Future<int> createLoan(Loan loan) async {
    final db = await _db();

    final active = await db.query(
      'loans',
      where: 'bookId = ? AND returnedAt IS NULL',
      whereArgs: [loan.bookId],
    );

    if (active.isNotEmpty) {
      throw Exception('Bu kitap şu anda emanet verilmiş durumda.');
    }

    return await db.insert('loans', loan.toMap());
  }

  /// Emanet güncelle
  Future<int> updateLoan(Loan loan) async {
    final db = await _db();

    return await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  /// Tüm emanetler
  Future<List<Loan>> getLoans() async {
    final db = await _db();
    final maps = await db.query('loans', orderBy: 'loanDate DESC');
    return maps.map((e) => Loan.fromMap(e)).toList();
  }

  /// Aktif emanetler
  Future<List<Loan>> getActiveLoans() async {
    final db = await _db();
    final maps = await db.query(
      'loans',
      where: 'returnedAt IS NULL',
      orderBy: 'dueDate ASC',
    );
    return maps.map((e) => Loan.fromMap(e)).toList();
  }

  /// Üyeye ait emanetler
  Future<List<Loan>> getLoansByMember(int memberId) async {
    final db = await _db();
    final maps = await db.query(
      'loans',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'loanDate DESC',
    );
    return maps.map((e) => Loan.fromMap(e)).toList();
  }

  /// Kitaba ait emanet geçmişi
  Future<List<Loan>> getLoansByBook(int bookId) async {
    final db = await _db();
    final maps = await db.query(
      'loans',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'loanDate DESC',
    );
    return maps.map((e) => Loan.fromMap(e)).toList();
  }

  /// Kitabı iade et
  Future<int> returnLoan(int loanId) async {
    final db = await _db();

    return await db.update(
      'loans',
      {
        'returnedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [loanId],
    );
  }

  /// Gecikmiş emanetleri getir (Kitap ve Üye bilgileriyle)
  Future<List<Map<String, dynamic>>> getOverdueLoans() async {
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    return await db.rawQuery(
      '''
      SELECT l.*, b.title as bookTitle, m.name as memberName 
      FROM loans l
      LEFT JOIN books b ON l.bookId = b.id
      LEFT JOIN members m ON l.memberId = m.id
      WHERE l.returnedAt IS NULL AND l.dueDate < ?
      ORDER BY l.dueDate ASC
    ''',
      [now],
    );
  }

  /// Son hareketler (Verilen/Alınan)
  Future<List<Map<String, dynamic>>> getRecentLoans({int limit = 10}) async {
    final db = await _db();
    return await db.rawQuery(
      '''
      SELECT l.*, b.title as bookTitle, m.name as memberName 
      FROM loans l
      LEFT JOIN books b ON l.bookId = b.id
      LEFT JOIN members m ON l.memberId = m.id
      ORDER BY l.updatedAt DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  /// Loan sil (admin/debug)
  Future<int> deleteLoan(int id) async {
    final db = await _db();
    return await db.delete('loans', where: 'id = ?', whereArgs: [id]);
  }
}

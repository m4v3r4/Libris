import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:libris/features/members/models/member.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/features/books/models/book.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

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

    await _ensureMembersTable(db);
    await _ensureLoansTable(db);
    await _ensureBooksTable(db);
    return db;
  }

  // --- MEMBERS ---
  /// Üyeler tablosunu oluşturur (Eğer yoksa)
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

  /// Yeni üye ekle
  Future<int> insertMember(Member member) async {
    final db = await database;
    return await db.insert(
      'members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Tüm üyeleri getir (Oluşturulma tarihine göre azalan)
  Future<List<Member>> getMembers() async {
    final db = await database;
    final maps = await db.query('members', orderBy: 'createdAt DESC');
    return maps.map(Member.fromMap).toList();
  }

  /// ID'ye göre üye getir
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

  /// Üye bilgilerini güncelle
  Future<int> updateMember(Member member) async {
    final db = await database;
    return await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  /// Üyeyi sil
  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  /// Üye ara (İsim, E-posta veya Telefon)
  Future<List<Member>> searchMembers(String query) async {
    final db = await database;
    final maps = await db.query(
      'members',
      where: 'name LIKE ? OR email LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map(Member.fromMap).toList();
  }

  /// En çok kitap okuyanlar (Emanet sayısına göre)
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

  /// Son eklenen üyeler
  Future<List<Member>> getLatestMembers({int limit = 5}) async {
    final db = await database;
    final maps = await db.query('members', orderBy: 'id DESC', limit: limit);
    return maps.map(Member.fromMap).toList();
  }

  // --- LOANS ---

  /// Emanetler tablosunu oluşturur
  Future<void> _ensureLoansTable(Database db) async {
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

  /// Yeni emanet oluştur (Kitap müsaitlik kontrolü ile)
  Future<int> createLoan(Loan loan) async {
    final db = await database;
    final active = await db.query(
      'loans',
      where: 'bookId = ? AND returnedAt IS NULL',
      whereArgs: [loan.bookId],
    );

    if (active.isNotEmpty) {
      throw Exception('Bu kitap şu anda emanet verilmiş durumda.');
    }

    final id = await db.insert('loans', loan.toMap());

    // Kitabın durumunu 'Emanette' (isAvailable = 0) olarak güncelle
    await db.update(
      'books',
      {'isAvailable': 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [loan.bookId],
    );

    return id;
  }

  /// Emanet kaydını güncelle
  Future<int> updateLoan(Loan loan) async {
    final db = await database;
    return await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  /// Tüm emanetleri getir
  Future<List<Loan>> getLoans() async {
    final db = await database;
    final maps = await db.query('loans', orderBy: 'loanDate DESC');
    return maps.map((e) => Loan.fromMap(e)).toList();
  }

  /// Aktif (iade edilmemiş) emanetleri detaylı getir
  Future<List<Map<String, dynamic>>> getActiveLoans() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT l.*, b.title as bookTitle, m.name as memberName 
      FROM loans l
      LEFT JOIN books b ON l.bookId = b.id
      LEFT JOIN members m ON l.memberId = m.id
      WHERE l.returnedAt IS NULL
      ORDER BY l.dueDate ASC
    ''');
  }

  /// Belirli bir üyeye ait emanetleri getir
  Future<List<Loan>> getLoansByMember(int memberId) async {
    final db = await database;
    final maps = await db.query(
      'loans',
      where: 'memberId = ?',
      whereArgs: [memberId],
      orderBy: 'loanDate DESC',
    );
    return maps.map((e) => Loan.fromMap(e)).toList();
  }

  /// Belirli bir kitaba ait emanet geçmişini getir
  Future<List<Loan>> getLoansByBook(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'loans',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'loanDate DESC',
    );
    return maps.map((e) => Loan.fromMap(e)).toList();
  }

  /// Kitabı iade al (Tarihi güncelle ve kitabı müsait yap)
  Future<int> returnLoan(int loanId) async {
    final db = await database;

    // 1. Emanet kaydını kapat
    final result = await db.update(
      'loans',
      {
        'returnedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [loanId],
    );

    // 2. Kitabın durumunu 'Müsait' (isAvailable = 1) yap
    // Önce loanId'den bookId'yi bulmamız lazım
    final loanMaps = await db.query(
      'loans',
      columns: ['bookId'],
      where: 'id = ?',
      whereArgs: [loanId],
    );
    if (loanMaps.isNotEmpty) {
      final bookId = loanMaps.first['bookId'] as int;
      await db.update(
        'books',
        {'isAvailable': 1, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [bookId],
      );
    }

    return result;
  }

  /// Gecikmiş (teslim tarihi geçmiş ve iade edilmemiş) emanetleri getir
  Future<List<Map<String, dynamic>>> getOverdueLoans() async {
    final db = await database;
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

  /// Son yapılan emanet işlemlerini getir
  Future<List<Map<String, dynamic>>> getRecentLoans({int limit = 10}) async {
    final db = await database;
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

  /// Emanet kaydını tamamen sil
  Future<int> deleteLoan(int id) async {
    final db = await database;
    return await db.delete('loans', where: 'id = ?', whereArgs: [id]);
  }

  // --- BOOKS ---

  /// Kitaplar tablosunu oluşturur ve eksik kolonları ekler
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

    // Migration: Tablo yapısındaki değişiklikleri kontrol et ve eksik kolonları ekle
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
      // Varsayılan olarak 1 (Müsait)
      await db.execute(
        'ALTER TABLE books ADD COLUMN isAvailable INTEGER DEFAULT 1',
      );
    }
  }

  /// Kitap Ekle
  Future<int> createBook(Book book) async {
    final db = await database;
    return await db.insert('books', book.toMap());
  }

  /// Tüm Kitapları Getir
  Future<List<Book>> getBooks() async {
    final db = await database;
    final maps = await db.query('books', orderBy: 'title ASC');
    return maps.map(Book.fromMap).toList();
  }

  /// Kategoriye göre kitapları getir
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

  /// Kitabın kategorisini güncelle
  Future<int> updateBookCategory(int bookId, String newCategory) async {
    final db = await database;
    return await db.update(
      'books',
      {'category': newCategory, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  /// ID'ye göre kitap detayını getir
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

  /// Kitap bilgilerini güncelle
  Future<int> updateBook(Book book) async {
    final db = await database;
    return await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  /// Kitabı sil
  Future<int> deleteBook(int id) async {
    final db = await database;
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  /// En çok okunan kitaplar (Emanet sayısına göre)
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

  /// Son eklenen kitaplar
  Future<List<Book>> getLatestBooks({int limit = 5}) async {
    final db = await database;
    final maps = await db.query('books', orderBy: 'id DESC', limit: limit);
    return maps.map(Book.fromMap).toList();
  }
}

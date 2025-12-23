import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:sqflite/sqflite.dart';

class BookService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Tabloyu oluştur
  Future<void> init() async {
    final db = await _dbHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        isbn TEXT,
        pageCount INTEGER,
        description TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  /// Kitap Ekle
  Future<int> createBook(Book book) async {
    final db = await _dbHelper.database;
    await init();
    return await db.insert('books', book.toMap());
  }

  /// Tüm Kitapları Getir
  Future<List<Book>> getBooks() async {
    final db = await _dbHelper.database;
    await init();
    final maps = await db.query('books', orderBy: 'title ASC');
    return maps.map(Book.fromMap).toList();
  }

  /// ID ile Kitap Getir
  Future<Book?> getBookById(int id) async {
    final db = await _dbHelper.database;
    await init();
    final maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Book.fromMap(maps.first) : null;
  }

  /// Kitap Güncelle
  Future<int> updateBook(Book book) async {
    final db = await _dbHelper.database;
    await init();
    return await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  /// Kitap Sil
  Future<int> deleteBook(int id) async {
    final db = await _dbHelper.database;
    await init();
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  /// En çok okunan kitaplar (Emanet sayısına göre)
  Future<List<Book>> getTopBooks({int limit = 5}) async {
    final db = await _dbHelper.database;
    await init();

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
    final db = await _dbHelper.database;
    await init();
    final maps = await db.query('books', orderBy: 'id DESC', limit: limit);
    return maps.map(Book.fromMap).toList();
  }
}

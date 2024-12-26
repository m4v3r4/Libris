import 'package:libris/Class/CustomBook.dart';
import 'package:libris/Service/DatabaseHelper.dart';
import 'package:sqflite/sqflite.dart';

class BookDao {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<void> insertBook(CustomBook book) async {
    final db = await dbHelper.database;
    await db.insert('books', book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CustomBook>> getAllBooks() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('books');

    // Veritabanından gelen her satırı CustomBook objesine dönüştür
    return List.generate(maps.length, (i) {
      return CustomBook.fromJson(maps[i]);
    });
  }

  Future<CustomBook?> getBookById(String id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1, // Performansı artırmak için yalnızca bir sonuç döndürülür
    );

    // Eğer sonuç varsa, CustomBook objesi oluşturulur. Yoksa null döner.
    if (maps.isNotEmpty) {
      return CustomBook.fromJson(maps.first);
    } else {
      return null; // Verilen ID ile kitap bulunamadı
    }
  }

  // Kitap sayısını döndüren fonksiyon
  Future<int> getBooksCount() async {
    final db = await dbHelper.database;
    final count = await db.rawQuery('SELECT COUNT(*) FROM books');
    return Sqflite.firstIntValue(count) ??
        0; // count sorgusu sonucu sıfır dönebilir, bu yüzden null kontrolü
  }

  // Arama ve filtreleme fonksiyonları
  Future<List<CustomBook>> searchBooks(String query) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'], // Başlıkta arama
    );
    return List.generate(maps.length, (i) => CustomBook.fromJson(maps[i]));
  }

  Future<List<CustomBook>> filterBooks(String filter) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps;

    if (filter == 'Tümü') {
      maps = await db.query('books');
    } else if (filter == 'Mevcut') {
      maps = await db.query('books', where: 'isAvailable = 1');
    } else if (filter == 'Ödünç Alınan') {
      maps = await db.query('books', where: 'isAvailable = 0');
    } else {
      maps = [];
    }

    return List.generate(maps.length, (i) => CustomBook.fromJson(maps[i]));
  }

  Future<void> updateBook(CustomBook book) async {
    final db = await dbHelper.database;
    await db
        .update('books', book.toMap(), where: 'id = ?', whereArgs: [book.id]);
  }

  Future<void> deleteBook(String id) async {
    final db = await dbHelper.database;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }
}

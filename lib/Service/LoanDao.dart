import 'package:libris/Class/Loan.dart';
import 'package:libris/Service/DatabaseHelper.dart';
import 'package:sqflite/sqflite.dart';

class LoanDao {
  // Tüm ödünçleri al
  Future<List<Loan>> getAllLoans() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('loans');

    // Verileri Loan nesnelerine dönüştürme
    return List.generate(maps.length, (i) {
      return Loan.fromJson(maps[i]);
    });
  }

  // Loan'ları kullanıcı adı veya soyadı ile arama
  Future<List<Loan>> searchLoansByUserName(String query) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM loans
      WHERE userId IN (
        SELECT id FROM users WHERE firstname LIKE ? OR lastname LIKE ?
      )
    ''', ['%$query%', '%$query%']);

    return List.generate(maps.length, (i) {
      return Loan.fromJson(maps[i]);
    });
  }

  // Loan'ları kitap adı ile arama (Kitap adı veritabanında bulunuyor varsayalım)
  Future<List<Loan>> searchLoansByBookName(String query) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM loans
      WHERE bookId IN (
        SELECT id FROM books WHERE name LIKE ?
      )
    ''', ['%$query%']);

    return List.generate(maps.length, (i) {
      return Loan.fromJson(maps[i]);
    });
  }

// Kullanıcı ID'sine göre ödünç alınan kitapları getir
  Future<List<Loan>> getLoansByUserId(String userId) async {
    final db = await DatabaseHelper().database;

    // Kullanıcı ID'sine göre 'loans' tablosundan ödünç alınan kitapları sorguluyoruz
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'userId = ?', // Kullanıcı ID'sine göre filtreleme
      whereArgs: [userId], // Parametre olarak kullanıcı ID'si
    );

    // Verileri Loan nesnelerine dönüştürme
    return List.generate(maps.length, (i) {
      return Loan.fromJson(maps[i]);
    });
  }

  Future<int> getLoanCount() async {
    final db = await DatabaseHelper().database;
    // 'loans' tablosundaki toplam satır sayısını alıyoruz
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM loans'));
    return count ?? 0; // Eğer count null ise 0 döndürüyoruz
  }

  // Loan ekle
  Future<void> addLoan(Loan loan) async {
    final db = await DatabaseHelper().database;
    await db.insert('loans', loan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Loan ID'ye göre veriyi al
  Future<Loan?> getLoanById(String id) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps =
        await db.query('loans', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Loan.fromJson(maps.first);
    } else {
      return null;
    }
  }

  // Loan güncelle
  Future<void> updateLoan(Loan loan) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  // Loan sil
  Future<void> deleteLoan(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

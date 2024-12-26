import 'package:libris/Class/CustomUser.dart';
import 'package:libris/Class/Loan.dart';
import 'package:libris/Service/DatabaseHelper.dart';
import 'package:sqflite/sqflite.dart';

class UserDao {
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<void> insertUser(CustomUser user) async {
    final db = await dbHelper.database;
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CustomUser>> getAllUsers() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => CustomUser.fromJson(maps[i]));
  }

  Future<void> updateUser(CustomUser user) async {
    final db = await dbHelper.database;
    await db
        .update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<List<Loan>> getLoansByUserId(String userId) async {
    final db = await dbHelper.database;

    // Kullanıcının ödünç aldığı kitaplar için loans tablosunu sorguluyoruz
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Veritabanından alınan raw verileri Loan nesnelerine dönüştürüyoruz
    return List.generate(maps.length, (i) {
      return Loan.fromJson(maps[i]);
    });
  }

  Future<int> getUserCount() async {
    final db = await dbHelper.database;
    // 'users' tablosunda kayıtlı kullanıcı sayısını alıyoruz
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'));
    return count ?? 0; // Eğer count null ise 0 döndürüyoruz
  }

  Future<CustomUser?> getUserById(String userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return CustomUser.fromJson(maps.first); // Kullanıcıyı döndür
    } else {
      return null; // Kullanıcı bulunamazsa null döndür
    }
  }

  Future<void> deleteUser(String id) async {
    final db = await dbHelper.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}

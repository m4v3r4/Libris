import 'package:libris/Class/CustomUser.dart';
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

  Future<void> deleteUser(String id) async {
    final db = await dbHelper.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}

import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/members/models/member.dart';
import 'package:sqflite/sqflite.dart';

class MembersService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// tabloyu garanti altına al
  Future<void> init() async {
    final db = await _dbHelper.database;

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

  /// CREATE
  Future<int> insertMember(Member member) async {
    final db = await _dbHelper.database;
    await init();

    return await db.insert(
      'members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// READ (ALL)
  Future<List<Member>> getMembers() async {
    final db = await _dbHelper.database;
    await init();

    final maps = await db.query('members', orderBy: 'createdAt DESC');

    return maps.map(Member.fromMap).toList();
  }

  /// READ (BY ID)
  Future<Member?> getMemberById(int id) async {
    final db = await _dbHelper.database;
    await init();

    final maps = await db.query(
      'members',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return maps.isNotEmpty ? Member.fromMap(maps.first) : null;
  }

  /// UPDATE
  Future<int> updateMember(Member member) async {
    final db = await _dbHelper.database;
    await init();

    return await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  /// DELETE
  Future<int> deleteMember(int id) async {
    final db = await _dbHelper.database;
    await init();

    return await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  /// SEARCH
  Future<List<Member>> searchMembers(String query) async {
    final db = await _dbHelper.database;
    await init();

    final maps = await db.query(
      'members',
      where: 'name LIKE ? OR email LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map(Member.fromMap).toList();
  }

  /// En çok kitap okuyanlar (Emanet sayısına göre)
  Future<List<Member>> getTopMembers({int limit = 5}) async {
    final db = await _dbHelper.database;
    await init();

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
    final db = await _dbHelper.database;
    await init();

    final maps = await db.query('members', orderBy: 'id DESC', limit: limit);

    return maps.map(Member.fromMap).toList();
  }
}

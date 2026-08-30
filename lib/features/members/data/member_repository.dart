import 'package:libris/common/models/member.dart';
import 'package:libris/features/categories/data/category_repository.dart';
import 'package:sqflite/sqflite.dart';

class MemberRepository {
  MemberRepository(this._database);

  final DatabaseGetter _database;

  Future<int> insert(Member member) async {
    final db = await _database();
    return db.insert(
      'members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Member>> getAll() async {
    final db = await _database();
    final maps = await db.query('members', orderBy: 'createdAt DESC');
    return maps.map(Member.fromMap).toList();
  }

  Future<Member?> getById(int id) async {
    final db = await _database();
    final maps = await db.query(
      'members',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Member.fromMap(maps.first) : null;
  }

  Future<int> update(Member member) async {
    final db = await _database();
    return db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _database();
    final loanCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM loans WHERE memberId = ?', [id]),
    );
    if ((loanCount ?? 0) > 0) {
      throw Exception(
        'Bu üyenin emanet geçmişi olduğu için silinemez. Önce emanet kayıtlarını temizleyin.',
      );
    }
    return db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Member>> search(String query) async {
    final db = await _database();
    final maps = await db.query(
      'members',
      where: 'name LIKE ? OR email LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map(Member.fromMap).toList();
  }

  Future<List<Member>> getTop({int limit = 5}) async {
    final db = await _database();
    final maps = await db.rawQuery(
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

  Future<List<Member>> getLatest({int limit = 5}) async {
    final db = await _database();
    final maps = await db.query('members', orderBy: 'id DESC', limit: limit);
    return maps.map(Member.fromMap).toList();
  }
}

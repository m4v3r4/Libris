import 'package:sqflite/sqflite.dart';

typedef DatabaseGetter = Future<Database> Function();

class CategoryRepository {
  CategoryRepository(this._database);

  final DatabaseGetter _database;

  Future<int?> resolveCategoryId(
    DatabaseExecutor executor,
    String? category,
  ) async {
    final name = category?.trim();
    if (name == null || name.isEmpty) return null;

    final rows = await executor.query(
      'categories',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return executor.insert('categories', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getWithStats() async {
    final db = await _database();
    return db.rawQuery('''
      SELECT c.id, c.name,
      (SELECT COUNT(*) FROM books b WHERE b.categoryId = c.id) as book_count
      FROM categories c
      ORDER BY c.name ASC
    ''');
  }

  Future<List<String>> getNames() async {
    final db = await _database();
    final result = await db.query(
      'categories',
      columns: ['name'],
      orderBy: 'name ASC',
    );
    return result.map((e) => e['name'] as String).toList();
  }

  Future<int> add(String name) async {
    final db = await _database();
    return db.insert('categories', {'name': name.trim()});
  }

  Future<int> update(int id, String newName) async {
    final db = await _database();
    return db.update(
      'categories',
      {'name': newName.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _database();
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM books WHERE categoryId = ?',
        [id],
      ),
    );
    if ((count ?? 0) > 0) {
      throw Exception(
        'Bu kategoriye ait $count adet kitap var. Önce kitapların kategorisini değiştirin.',
      );
    }
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}

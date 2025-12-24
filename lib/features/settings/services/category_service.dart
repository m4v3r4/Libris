import 'package:sqflite/sqflite.dart';

class CategoryService {
  // Veritabanı erişimi için fonksiyon (Mevcut yapınıza göre düzenleyebilirsiniz)
  final Future<Database> Function() _getDb;

  CategoryService(this._getDb);

  /// Tabloyu oluştur ve mevcut kitaplardan verileri çek
  Future<void> init() async {
    final db = await _getDb();

    // 1. Kategoriler tablosunu oluştur
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // 2. Mevcut kitaplardaki kategorileri buraya aktar (Migration)
    // Not: 'books' tablosunda 'category' sütunu olduğu varsayılmıştır.
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories'),
    );
    if (count == 0) {
      try {
        // Boş olmayan ve tekrarsız kategorileri seç
        final result = await db.rawQuery(
          'SELECT DISTINCT category FROM books WHERE category IS NOT NULL AND category != ""',
        );

        final batch = db.batch();
        for (var row in result) {
          batch.insert('categories', {
            'name': row['category'],
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
      } catch (e) {
        // books tablosu henüz yoksa veya category sütunu yoksa hata yutulur
        print('Migration uyarısı: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCategoriesWithStats() async {
    final db = await _getDb();
    // Kategorileri ve her kategoride kaç kitap olduğunu getirir
    // Not: İlişki şu an 'name' üzerinden kuruluyor. İleride ID'ye çevrilirse sorgu güncellenmeli.
    return await db.rawQuery('''
      SELECT c.id, c.name, 
      (SELECT COUNT(*) FROM books b WHERE b.category = c.name) as book_count
      FROM categories c
      ORDER BY c.name ASC
    ''');
  }

  Future<List<String>> getCategoryNames() async {
    final db = await _getDb();
    final result = await db.query(
      'categories',
      columns: ['name'],
      orderBy: 'name ASC',
    );
    return result.map((e) => e['name'] as String).toList();
  }

  Future<int> addCategory(String name) async {
    final db = await _getDb();
    return await db.insert('categories', {'name': name});
  }

  Future<int> updateCategory(int id, String newName) async {
    final db = await _getDb();
    // Kitaplardaki eski kategori ismini de güncellemek gerekir (Eğer Foreign Key yoksa)
    await db.transaction((txn) async {
      final oldNameMap = await txn.query(
        'categories',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [id],
      );
      if (oldNameMap.isNotEmpty) {
        final oldName = oldNameMap.first['name'] as String;
        await txn.update(
          'books',
          {'category': newName},
          where: 'category = ?',
          whereArgs: [oldName],
        );
      }
      await txn.update(
        'categories',
        {'name': newName},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    return id;
  }

  Future<void> deleteCategory(int id, String name) async {
    final db = await _getDb();
    // Kullanım kontrolü: Eğer bu kategoride kitap varsa silme
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM books WHERE category = ?', [
        name,
      ]),
    );
    if (count != null && count > 0) {
      throw Exception(
        'Bu kategoriye ait $count adet kitap var. Önce kitapların kategorisini değiştirin.',
      );
    }
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}

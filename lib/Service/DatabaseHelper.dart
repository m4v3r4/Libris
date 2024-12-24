import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart'; // sqflite'yi kullanın
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'library.db');

    // Debugging: Veritabanı dosya yolu
    print("Veritabanı yolu: $path");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) {
        // Debugging: Veritabanı açıldığında
        print("Veritabanı açıldı.");
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print("Veritabanı oluşturuluyor...");

    // Book tablosu
    await db.execute('''
    CREATE TABLE books (
      id TEXT PRIMARY KEY,
      title TEXT,
      authors TEXT,
      description TEXT,
      thumbnail TEXT,
      publisher TEXT,
      publishedDate TEXT,
      pageCount INTEGER,
      shelf TEXT,
      rack TEXT,
      isAvailable INTEGER,
      currentUserId TEXT,
      isbn TEXT
    )
  ''');
    print("Kitap tablosu oluşturuldu.");

    // User tablosu
    await db.execute('''CREATE TABLE users (
  id TEXT PRIMARY KEY,
  firstname TEXT,
  lastname TEXT,
  email TEXT,
  phoneNumber TEXT,
  borrowedBooksIds TEXT,  -- Burada sadece kitapların ID'lerini saklıyoruz
  studentId TEXT,
  faculty TEXT,
  department TEXT
)''');
    print("Kullanıcı tablosu oluşturuldu.");

    // Loan tablosu
    await db.execute('''
      CREATE TABLE loans(
        id TEXT PRIMARY KEY,
        userId TEXT,
        userFirstName TEXT,
        userLastName TEXT,
        bookId TEXT,
        bookName TEXT,
        loanDate TEXT,
        returnDate TEXT
      )
    ''');

    print("Ödünç tablosu oluşturuldu.");
  }
}

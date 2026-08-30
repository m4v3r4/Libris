import 'package:sqflite/sqflite.dart';

Future<void> createSchemaV2(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT,
      phone TEXT,
      address TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE
    )
  ''');

  await db.execute('''
    CREATE TABLE books (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      author TEXT NOT NULL,
      isbn TEXT,
      publisher TEXT,
      publishYear INTEGER,
      pageCount INTEGER,
      description TEXT,
      categoryId INTEGER,
      location TEXT,
      isAvailable INTEGER DEFAULT 1,
      createdAt TEXT,
      updatedAt TEXT,
      FOREIGN KEY (categoryId) REFERENCES categories(id) ON UPDATE CASCADE ON DELETE RESTRICT
    )
  ''');

  await db.execute('''
    CREATE TABLE book_copies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bookId INTEGER NOT NULL,
      inventoryCode TEXT NOT NULL UNIQUE,
      status TEXT NOT NULL DEFAULT 'available',
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (bookId) REFERENCES books(id) ON UPDATE CASCADE ON DELETE RESTRICT
    )
  ''');

  await db.execute('''
    CREATE TABLE loans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bookId INTEGER NOT NULL,
      memberId INTEGER NOT NULL,
      copyId INTEGER,
      loanDate TEXT NOT NULL,
      dueDate TEXT NOT NULL,
      returnedAt TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (bookId) REFERENCES books(id) ON UPDATE CASCADE ON DELETE RESTRICT,
      FOREIGN KEY (memberId) REFERENCES members(id) ON UPDATE CASCADE ON DELETE RESTRICT
    )
  ''');

  await db.execute('CREATE INDEX idx_books_categoryId ON books(categoryId)');
  await db.execute(
    'CREATE INDEX idx_book_copies_bookId ON book_copies(bookId)',
  );
  await db.execute(
    'CREATE INDEX idx_book_copies_status ON book_copies(status)',
  );
  await db.execute('CREATE INDEX idx_loans_copyId ON loans(copyId)');
}

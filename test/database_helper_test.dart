import 'package:flutter_test/flutter_test.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/common/models/member.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:libris/features/books/models/book_copy.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late DatabaseHelper helper;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        singleInstance: false,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
    helper = DatabaseHelper.forTesting(database);
    await helper.initializeSchemaForTesting();
  });

  tearDown(() async {
    await database.close();
  });

  Future<({int bookId, int memberId})> seedBookAndMember() async {
    final bookId = await helper.createBook(
      Book(
        title: 'Test Kitabı',
        author: 'Test Yazarı',
        description: 'Test açıklaması',
      ),
    );
    final memberId = await helper.insertMember(Member(name: 'Test Üye'));
    return (bookId: bookId, memberId: memberId);
  }

  Loan makeLoan({
    required int bookId,
    required int memberId,
    int? copyId,
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    return Loan(
      bookId: bookId,
      memberId: memberId,
      copyId: copyId,
      loanDate: now,
      dueDate: dueDate ?? now.add(const Duration(days: 14)),
    );
  }

  test('new books receive one available physical copy', () async {
    final fixture = await seedBookAndMember();

    final copies = await helper.getBookCopies(fixture.bookId);
    final stats = await helper.getBookCopyStats(fixture.bookId);

    expect(copies, hasLength(1));
    expect(copies.single.status, BookCopyStatus.available);
    expect(copies.single.inventoryCode, startsWith('LBR-'));
    expect(stats['total'], 1);
    expect(stats['available'], 1);
  });

  test('creating a loan assigns and loans the physical copy', () async {
    final fixture = await seedBookAndMember();

    await helper.createLoan(
      makeLoan(bookId: fixture.bookId, memberId: fixture.memberId),
    );

    final book = await helper.getBookById(fixture.bookId);
    final copies = await helper.getBookCopies(fixture.bookId);
    final loans = await helper.getLoans();

    expect(book, isNotNull);
    expect(book!.isAvailable, isFalse);
    expect(copies.single.status, BookCopyStatus.loaned);
    expect(loans.single.copyId, copies.single.id);
  });

  test('two copies allow two active loans but reject a third', () async {
    final fixture = await seedBookAndMember();
    final secondMemberId = await helper.insertMember(Member(name: 'İkinci Üye'));
    await helper.createBookCopy(fixture.bookId);
    final copies = await helper.getBookCopies(fixture.bookId);

    await helper.createLoan(
      makeLoan(
        bookId: fixture.bookId,
        memberId: fixture.memberId,
        copyId: copies[0].id,
      ),
    );

    var book = await helper.getBookById(fixture.bookId);
    expect(book!.isAvailable, isTrue);

    await helper.createLoan(
      makeLoan(
        bookId: fixture.bookId,
        memberId: secondMemberId,
        copyId: copies[1].id,
      ),
    );

    book = await helper.getBookById(fixture.bookId);
    expect(book!.isAvailable, isFalse);

    await expectLater(
      helper.createLoan(
        makeLoan(bookId: fixture.bookId, memberId: fixture.memberId),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('returning a loan makes its copy available again', () async {
    final fixture = await seedBookAndMember();
    final loanId = await helper.createLoan(
      makeLoan(bookId: fixture.bookId, memberId: fixture.memberId),
    );

    final loansBeforeReturn = await helper.getLoans();
    final copyId = loansBeforeReturn.single.copyId!;
    final updated = await helper.returnLoan(loanId);

    expect(updated, 1);
    final copy = await helper.getBookCopyById(copyId);
    expect(copy!.status, BookCopyStatus.available);
    final book = await helper.getBookById(fixture.bookId);
    expect(book!.isAvailable, isTrue);
    final loans = await helper.getLoans();
    expect(loans.single.returnedAt, isNotNull);
  });

  test('deleting an active loan makes its copy available again', () async {
    final fixture = await seedBookAndMember();
    final loanId = await helper.createLoan(
      makeLoan(bookId: fixture.bookId, memberId: fixture.memberId),
    );
    final copyId = (await helper.getLoans()).single.copyId!;

    final deleted = await helper.deleteLoan(loanId);

    expect(deleted, 1);
    expect(await helper.getLoans(), isEmpty);
    final copy = await helper.getBookCopyById(copyId);
    expect(copy!.status, BookCopyStatus.available);
    final book = await helper.getBookById(fixture.bookId);
    expect(book!.isAvailable, isTrue);
  });

  test('lost and maintenance copies are not available for loan', () async {
    final fixture = await seedBookAndMember();
    final copy = (await helper.getBookCopies(fixture.bookId)).single;

    await helper.updateBookCopyStatus(copy.id!, BookCopyStatus.lost);
    var book = await helper.getBookById(fixture.bookId);
    expect(book!.isAvailable, isFalse);
    expect(await helper.getAvailableBookCopies(fixture.bookId), isEmpty);

    await helper.updateBookCopyStatus(copy.id!, BookCopyStatus.maintenance);
    book = await helper.getBookById(fixture.bookId);
    expect(book!.isAvailable, isFalse);

    await helper.updateBookCopyStatus(copy.id!, BookCopyStatus.available);
    book = await helper.getBookById(fixture.bookId);
    expect(book!.isAvailable, isTrue);
  });

  test('copies with loan history cannot be deleted', () async {
    final fixture = await seedBookAndMember();
    final loanId = await helper.createLoan(
      makeLoan(bookId: fixture.bookId, memberId: fixture.memberId),
    );
    final copyId = (await helper.getLoans()).single.copyId!;
    await helper.returnLoan(loanId);

    await expectLater(
      helper.deleteBookCopy(copyId),
      throwsA(isA<Exception>()),
    );
  });

  test('member and book with loan history cannot be deleted', () async {
    final fixture = await seedBookAndMember();
    final loanId = await helper.createLoan(
      makeLoan(bookId: fixture.bookId, memberId: fixture.memberId),
    );
    await helper.returnLoan(loanId);

    await expectLater(
      helper.deleteMember(fixture.memberId),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      helper.deleteBook(fixture.bookId),
      throwsA(isA<Exception>()),
    );
  });

  test('overdue active loan includes copy inventory code', () async {
    final fixture = await seedBookAndMember();
    await helper.createLoan(
      makeLoan(
        bookId: fixture.bookId,
        memberId: fixture.memberId,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );

    final overdue = await helper.getOverdueLoans();

    expect(overdue, hasLength(1));
    expect(overdue.single['bookTitle'], 'Test Kitabı');
    expect(overdue.single['memberName'], 'Test Üye');
    expect(overdue.single['inventoryCode'], isNotNull);
  });

  test('legacy v1.1 rows are backfilled without losing loan history', () async {
    final legacyDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );

    try {
      await legacyDb.execute('''
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
      await legacyDb.execute('''
        CREATE TABLE books (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          author TEXT NOT NULL,
          isbn TEXT,
          publisher TEXT,
          publishYear INTEGER,
          pageCount INTEGER,
          description TEXT,
          category TEXT,
          location TEXT,
          isAvailable INTEGER DEFAULT 1,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
      await legacyDb.execute('''
        CREATE TABLE loans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bookId INTEGER NOT NULL,
          memberId INTEGER NOT NULL,
          loanDate TEXT NOT NULL,
          dueDate TEXT NOT NULL,
          returnedAt TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');

      final now = DateTime.now().toIso8601String();
      final bookId = await legacyDb.insert('books', {
        'title': 'Eski Kitap',
        'author': 'Eski Yazar',
        'description': 'Legacy kayıt',
        'isAvailable': 0,
        'createdAt': now,
        'updatedAt': now,
      });
      final memberId = await legacyDb.insert('members', {
        'name': 'Eski Üye',
        'createdAt': now,
        'updatedAt': now,
      });
      await legacyDb.insert('loans', {
        'bookId': bookId,
        'memberId': memberId,
        'loanDate': now,
        'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'returnedAt': null,
        'createdAt': now,
        'updatedAt': now,
      });

      final legacyHelper = DatabaseHelper.forTesting(legacyDb);
      await legacyHelper.initializeSchemaForTesting();

      final copies = await legacyHelper.getBookCopies(bookId);
      final loans = await legacyHelper.getLoans();
      final book = await legacyHelper.getBookById(bookId);

      expect(copies, hasLength(1));
      expect(copies.single.status, BookCopyStatus.loaned);
      expect(loans, hasLength(1));
      expect(loans.single.copyId, copies.single.id);
      expect(book!.title, 'Eski Kitap');
      expect(book.isAvailable, isFalse);
    } finally {
      await legacyDb.close();
    }
  });
}

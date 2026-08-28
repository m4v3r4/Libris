import 'package:flutter_test/flutter_test.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/common/models/member.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';
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
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    return Loan(
      bookId: bookId,
      memberId: memberId,
      loanDate: now,
      dueDate: dueDate ?? now.add(const Duration(days: 14)),
    );
  }

  test('emanet oluşturunca kitap müsait olmaktan çıkar', () async {
    final fixture = await seedBookAndMember();

    await helper.createLoan(
      makeLoan(bookId: fixture.bookId, memberId: fixture.memberId),
    );

    final book = await helper.getBookById(fixture.bookId);
    expect(book, isNotNull);
    expect(book!.isAvailable, isFalse);
  });

  test('aynı kitap aktifken ikinci kez emanet verilemez', () async {
    final fixture = await seedBookAndMember();
    final loan = makeLoan(
      bookId: fixture.bookId,
      memberId: fixture.memberId,
    );

    await helper.createLoan(loan);

    await expectLater(
      helper.createLoan(
        makeLoan(bookId: fixture.bookId, memberId: fixture.memberId),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('iade alınca kitap tekrar müsait olur', () async {
    final fixture = await seedBookAndMember();
    final loanId = await helper.createLoan(
      makeLoan(bookId: fixture.bookId, memberId: fixture.memberId),
    );

    final updated = await helper.returnLoan(loanId);

    expect(updated, 1);
    final book = await helper.getBookById(fixture.bookId);
    expect(book!.isAvailable, isTrue);
    final loans = await helper.getLoans();
    expect(loans.single.returnedAt, isNotNull);
  });

  test('aktif emanet silinince kitap tekrar müsait olur', () async {
    final fixture = await seedBookAndMember();
    final loanId = await helper.createLoan(
      makeLoan(bookId: fixture.bookId, memberId: fixture.memberId),
    );

    final deleted = await helper.deleteLoan(loanId);

    expect(deleted, 1);
    expect(await helper.getLoans(), isEmpty);
    final book = await helper.getBookById(fixture.bookId);
    expect(book!.isAvailable, isTrue);
  });

  test('emanet geçmişi olan üye ve kitap doğrudan silinemez', () async {
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

  test('teslim tarihi geçen aktif emanet gecikmiş listesinde görünür', () async {
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
  });
}

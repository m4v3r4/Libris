import 'package:flutter/foundation.dart';
import 'package:libris/common/database/app_database.dart';
import 'package:libris/common/database/migrations/v1_to_v2.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/common/models/member.dart';
import 'package:libris/features/books/data/book_repository.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:libris/features/books/models/book_copy.dart';
import 'package:libris/features/categories/data/category_repository.dart';
import 'package:libris/features/loans/data/loan_repository.dart';
import 'package:libris/features/members/data/member_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Backwards-compatible facade for the application's database operations.
///
/// Schema creation and migrations live under `common/database`, while feature
/// CRUD and query logic lives in repositories. Existing callers can continue
/// using this class while screens/providers migrate to repositories gradually.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Database? _database;

  DatabaseHelper._privateConstructor();

  @visibleForTesting
  DatabaseHelper.forTesting(Database database) : _database = database;

  late final CategoryRepository _categories = CategoryRepository(() => database);
  late final MemberRepository _members = MemberRepository(() => database);
  late final BookRepository _books = BookRepository(() => database, _categories);
  late final LoanRepository _loans = LoanRepository(() => database, _books);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await AppDatabase.open();
    return _database!;
  }

  @visibleForTesting
  Future<void> initializeSchemaForTesting() async {
    await migrateV1ToV2(await database);
  }

  // Categories
  Future<List<Map<String, dynamic>>> getCategoriesWithStats() =>
      _categories.getWithStats();

  Future<List<String>> getCategoryNames() => _categories.getNames();

  Future<int> addCategory(String name) => _categories.add(name);

  Future<int> updateCategory(int id, String newName) =>
      _categories.update(id, newName);

  Future<void> deleteCategory(int id, String _) => _categories.delete(id);

  // Members
  Future<int> insertMember(Member member) => _members.insert(member);

  Future<List<Member>> getMembers() => _members.getAll();

  Future<Member?> getMemberById(int id) => _members.getById(id);

  Future<int> updateMember(Member member) => _members.update(member);

  Future<int> deleteMember(int id) => _members.delete(id);

  Future<List<Member>> searchMembers(String query) => _members.search(query);

  Future<List<Member>> getTopMembers({int limit = 5}) =>
      _members.getTop(limit: limit);

  Future<List<Member>> getLatestMembers({int limit = 5}) =>
      _members.getLatest(limit: limit);

  // Books and physical copies
  Future<List<BookCopy>> getBookCopies(int bookId) => _books.getCopies(bookId);

  Future<List<BookCopy>> getAvailableBookCopies(int bookId) =>
      _books.getAvailableCopies(bookId);

  Future<BookCopy?> getBookCopyById(int id) => _books.getCopyById(id);

  Future<Map<String, int>> getBookCopyStats(int bookId) =>
      _books.getCopyStats(bookId);

  Future<int> createBookCopy(
    int bookId, {
    String? inventoryCode,
    BookCopyStatus status = BookCopyStatus.available,
  }) => _books.createCopy(
    bookId,
    inventoryCode: inventoryCode,
    status: status,
  );

  Future<int> updateBookCopyStatus(int copyId, BookCopyStatus status) =>
      _books.updateCopyStatus(copyId, status);

  Future<int> deleteBookCopy(int copyId) => _books.deleteCopy(copyId);

  Future<int> createBook(Book book) => _books.create(book);

  Future<List<Book>> getBooks() => _books.getAll();

  Future<List<Book>> getBooksByCategory(String category) =>
      _books.getByCategory(category);

  Future<int> updateBookCategory(int bookId, String newCategory) =>
      _books.updateCategory(bookId, newCategory);

  Future<Book?> getBookById(int id) => _books.getById(id);

  Future<int> updateBook(Book book) => _books.update(book);

  Future<int> deleteBook(int id) => _books.delete(id);

  Future<List<Book>> getTopBooks({int limit = 5}) =>
      _books.getTop(limit: limit);

  Future<List<Book>> getLatestBooks({int limit = 5}) =>
      _books.getLatest(limit: limit);

  // Loans
  Future<int> createLoan(Loan loan) => _loans.create(loan);

  Future<int> updateLoan(Loan loan) => _loans.update(loan);

  Future<List<Loan>> getLoans() => _loans.getAll();

  Future<List<Map<String, dynamic>>> getActiveLoans() => _loans.getActive();

  Future<List<Loan>> getLoansByMember(int memberId) =>
      _loans.getByMember(memberId);

  Future<List<Loan>> getLoansByBook(int bookId) => _loans.getByBook(bookId);

  Future<int> returnLoan(int loanId) => _loans.returnLoan(loanId);

  Future<List<Map<String, dynamic>>> getOverdueLoans() => _loans.getOverdue();

  Future<List<Map<String, dynamic>>> getRecentLoans({int limit = 10}) =>
      _loans.getRecent(limit: limit);

  Future<int> deleteLoan(int id) => _loans.delete(id);
}

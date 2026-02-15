import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libris/common/models/Member.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/features/books/models/book.dart';

class DatabaseProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// DatabaseHelper örneğine erişim
  DatabaseHelper get db => _dbHelper;

  /// Veritabanında bir değişiklik olduğunda (Ekleme, Silme, Güncelleme)
  /// bu metodu çağırarak dinleyen widget'ların yenilenmesini sağlayabilirsiniz.
  ///
  /// Örnek: context.read<DatabaseProvider>().refresh();
  void refresh() {
    notifyListeners();
  }

  // --- Üye İşlemleri ---
  Future<List<Member>> getMembers() async {
    return await _dbHelper.getMembers();
  }

  Future<int> addMember(Member member) async {
    final id = await _dbHelper.insertMember(member);
    notifyListeners(); // Değişikliği dinleyenlere bildir
    return id;
  }

  Future<int> updateMember(Member member) async {
    final count = await _dbHelper.updateMember(member);
    notifyListeners(); // Değişikliği dinleyenlere bildir
    return count;
  }

  Future<int> deleteMember(int id) async {
    final count = await _dbHelper.deleteMember(id);
    notifyListeners(); // Değişikliği dinleyenlere bildir
    return count;
  }

  // --- Kitap İşlemleri ---
  Future<List<Book>> getBooks() async {
    return await _dbHelper.getBooks();
  }

  Future<int> addBook(Book book) async {
    final id = await _dbHelper.createBook(book);
    notifyListeners();
    return id;
  }

  Future<int> updateBook(Book book) async {
    final count = await _dbHelper.updateBook(book);
    notifyListeners();
    return count;
  }

  Future<int> deleteBook(int id) async {
    final count = await _dbHelper.deleteBook(id);
    notifyListeners();
    return count;
  }

  // --- Kategori İşlemleri ---
  Future<List<Map<String, dynamic>>> getCategoriesWithStats() async {
    return await _dbHelper.getCategoriesWithStats();
  }

  Future<int> addCategory(String name) async {
    final id = await _dbHelper.addCategory(name);
    notifyListeners();
    return id;
  }

  Future<void> deleteCategory(int id, String name) async {
    await _dbHelper.deleteCategory(id, name);
    notifyListeners();
  }

  // --- Emanet (Loan) İşlemleri ---
  Future<List<Map<String, dynamic>>> getActiveLoans() async {
    return await _dbHelper.getActiveLoans();
  }

  Future<List<Loan>> getLoans() async {
    return await _dbHelper.getLoans();
  }

  Future<int> createLoan(Loan loan) async {
    final id = await _dbHelper.createLoan(loan);
    notifyListeners(); // Kitap durumu değiştiği için arayüz yenilenmeli
    return id;
  }

  Future<int> returnLoan(int loanId) async {
    final count = await _dbHelper.returnLoan(loanId);
    notifyListeners(); // Kitap müsait duruma geçtiği için arayüz yenilenmeli
    return count;
  }

  Future<List<Map<String, dynamic>>> getOverdueLoans() async {
    return await _dbHelper.getOverdueLoans();
  }
}

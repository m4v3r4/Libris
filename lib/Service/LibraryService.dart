import 'dart:io';

import 'package:libris/Class/Loan.dart';
import 'package:libris/Class/CustomBook.dart';
import 'package:libris/Class/CustomUser.dart';
import 'package:libris/Service/BookDao.dart';
import 'package:libris/Service/UserDao.dart';
import 'package:libris/Service/LoanDao.dart';
import 'package:sqflite/sqflite.dart';
import 'package:excel/excel.dart';

class LibraryService {
  final BookDao bookDao = BookDao();
  final UserDao userDao = UserDao();
  final LoanDao loanDao = LoanDao();

  // Kitap ödünç verme işlemi
  Future<void> borrowBook(String userId, String bookId) async {
    final user = await userDao.getUserById(userId);
    final book = await bookDao.getBookById(bookId);

    if (user == null || book == null) {
      throw Exception("Kullanıcı ya da kitap bulunamadı.");
    }

    // Eğer kitap mevcut değilse, ödünç verilemez
    if (book.isAvailable == 0) {
      throw Exception("Kitap zaten ödünç verilmiş.");
    }

    // Loan (ödünç) oluşturuluyor
    final loanId = DateTime.now().millisecondsSinceEpoch.toString();
    final loan = Loan(
      id: loanId,
      userId: user.id,
      userFirstName: user.firstname,
      userLastName: user.lastname,
      bookId: book.id,
      bookName: book.title,
      loanDate: DateTime.now(),
      returnDate: null, // Henüz geri alınmadı
    );

    // Loan kaydını veritabanına ekle
    await loanDao.addLoan(loan);

    // Kitap durumunu güncelle (ödünç verildi)
    book.isAvailable = 0; // Kitap artık mevcut değil
    book.currentUserId = user.id;
    await bookDao.updateBook(book);

    // Kullanıcının ödünç alınan kitap listesine kitap ID'sini ekle
    user.borrowedBooksIds.add(loanId);
    await userDao.updateUser(user);

    print("Kitap başarıyla ödünç verildi.");
  }

  // Kitap teslim alma işlemi (geri alma)
  Future<void> returnBook(String loanId) async {
    final loan = await loanDao.getLoanById(loanId);
    if (loan == null) {
      throw Exception("Ödünç verilen kitap bulunamadı.");
    }

    final book = await bookDao.getBookById(loan.bookId);
    final user = await userDao.getUserById(loan.userId);

    if (book == null || user == null) {
      throw Exception("Kitap ya da kullanıcı bulunamadı.");
    }

    // Kitap durumunu güncelle (geri alındı)
    book.isAvailable = 1; // Kitap artık mevcut
    book.currentUserId = null; // Kitap artık bir kullanıcıya ait değil
    await bookDao.updateBook(book);

    // Kullanıcının ödünç alınan kitap listesinde ilgili kitabı kaldır
    user.borrowedBooksIds.remove(loan.id);
    await userDao.updateUser(user);

    // Loan'ı güncelle (kitap geri alındı)
    loan.returnDate = DateTime.now();
    await loanDao.updateLoan(loan);

    print("Kitap başarıyla geri alındı.");
  }

  // Kullanıcı adı ile ödünçleri arama
  Future<List<Loan>> searchLoansByUserName(String query) async {
    return await loanDao.searchLoansByUserName(query);
  }

  // Kullanıcı id ile ödünçleri arama
  Future<List<Loan>> getLoansByIds(String query) async {
    return await loanDao.getLoansByUserId(query);
  }

  // Kitap adı ile ödünçleri arama
  Future<List<Loan>> searchLoansByBookName(String query) async {
    return await loanDao.searchLoansByBookName(query);
  }

  // Kullanıcı ID'si ile kullanıcıyı al
  Future<CustomUser?> getUserById(String userId) async {
    return await userDao.getUserById(userId);
  }

  // Kitap ID'si ile kitabı al
  Future<CustomBook?> getBookById(String bookId) async {
    return await bookDao.getBookById(bookId);
  }

  // Tüm ödünçleri al
  Future<List<Loan>> getAllLoans() async {
    return await loanDao.getAllLoans();
  }

  // Kitapları Excel'e dışa aktarma
  Future<void> exportBooksToExcel(
      String filePath, List<CustomBook> books) async {
    // Yeni bir Excel dosyası oluştur
    var excel = Excel.createExcel();

    // Yeni bir sayfa oluştur
    var sheet = excel['Books'];

    // Başlık satırını ekle
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Title'),
      TextCellValue('Thumbnail'),
      TextCellValue('Description'),
      TextCellValue('ISBN'),
      TextCellValue('Publisher'),
      TextCellValue('Author'),
      TextCellValue('Published Date'),
      TextCellValue('Is Available'),
      TextCellValue('Current User ID'),
    ]);

    // Kitap verilerini ekle
    for (var book in books) {
      sheet.appendRow([
        IntCellValue(int.parse(book.id)),
        TextCellValue(book.title),
        TextCellValue(book.thumbnail),
        TextCellValue(book.description),
        TextCellValue(book.isbn),
        TextCellValue(book.publisher),
        TextCellValue(book.authors.toList().toString()),
        TextCellValue(book.publishedDate.toString()),
        TextCellValue(book.isAvailable == 1 ? 'Yes' : 'No'),
        TextCellValue(book.currentUserId?.toString() ?? ''),
      ]);
    }

    // Varsayılan sayfayı ayarla
    excel.setDefaultSheet(sheet.sheetName);

    // Dosyayı kaydet
    List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      print("Kitaplar başarıyla dışa aktarıldı: $filePath");
    } else {
      print("Dosya kaydedilemedi.");
    }
  }

  Future<List<CustomBook>> importBooksFromExcel(String filePath) async {
    // Dosyayı aç
    var file = File(filePath);
    if (!file.existsSync()) {
      print("Dosya bulunamadı.");
      return [];
    }

    // Excel dosyasını oku
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    if (excel == null || excel.tables.isEmpty) {
      print("Excel dosyası okunamadı veya tablo bulunamadı.");
      return [];
    }

    // İlk sayfayı al
    var sheet = excel.tables.values.first;

    if (sheet == null) {
      print("Sayfa bulunamadı.");
      return [];
    }

    // Başlıkları atla ve verileri al
    List<CustomBook> books = [];
    bool isHeaderRow = true;

    for (var row in sheet.rows) {
      if (isHeaderRow) {
        isHeaderRow = false; // Başlık satırını atla
        continue;
      }

      // Satırdaki verileri CustomBook'a dönüştür
      var id = row[0]?.value.toString();
      var title = row[1]?.value.toString();
      var thumbnail = row[2]?.value.toString();

      var description = row[3]?.value.toString();
      var isbn = row[4]?.value.toString();
      var publisher = row[5]?.value.toString();
      var authors = row[6]?.value.toString();
      var publishedDate = row[7]?.value.toString();
      var isAvailable = row[8]?.value.toString() == 'Yes' ? 1 : 0;
      var currentUserId = row[9]?.value.toString();

      if (id != null && title != null) {
        // Tarih dönüşümünü yap
        DateTime? parsedDate = DateTime.tryParse(publishedDate ?? '');
        String dateString = parsedDate?.toString() ??
            'Tarih yok'; // Geçerli bir tarih değilse, 'Tarih yok' yazılır.

        CustomBook book = CustomBook(
          id: id,
          title: title,
          authors: authors?.split(',') ?? [],
          publishedDate: dateString,
          isAvailable: isAvailable,
          currentUserId: currentUserId,
          description: description.toString(),
          thumbnail: thumbnail.toString(),
          publisher: publisher.toString(),
          pageCount: 0,
          shelf: '',
          isbn: isbn.toString(),
          rack: '',
        );
        books.add(book);
      }
    }

    // Kitapları veritabanına ekle
    print("Kitaplar başarıyla içe aktarıldı.");
    for (var book in books) {
      try {
        await LibraryService().bookDao.insertBook(book);
      } catch (e) {
        print("Kitap eklenirken bir hata oluştu: $e");
      }
    }

    print("Yeni ${books.length} kitap eklendi.");
    return books;
  }
}

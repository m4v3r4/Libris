import 'package:flutter/material.dart';
import 'package:libris/Class/CustomBook.dart';
import 'package:libris/Service/DatabaseHelper.dart';
import 'package:libris/Service/UserDao.dart';
import 'package:libris/Class/CustomUser.dart';
import 'package:libris/Class/Loan.dart';
import 'package:libris/Service/BookDao.dart'; // Kitapları getiren bir servis
import 'package:libris/Service/LibraryService.dart'; // Yeni servisi import ettik

class AddLoanPage extends StatefulWidget {
  @override
  _AddLoanPageState createState() => _AddLoanPageState();
}

class _AddLoanPageState extends State<AddLoanPage> {
  final LibraryService libraryService =
      LibraryService(); // LibraryService'i kullanıyoruz
  List<CustomUser> users = [];
  List<String> bookIds = []; // Kitap ID'leri listesi
  List<String> bookNames = []; // Kitap isimleri listesi
  CustomUser? selectedUser;
  String? selectedBookId;
  String? selectedBookName;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadBooks(); // Kitapları yükleme
  }

  // Kullanıcıları yükleme
  Future<void> _loadUsers() async {
    users = await libraryService.userDao
        .getAllUsers(); // LibraryService üzerinden kullanıcıları al
    setState(() {});
  }

  // Kitapları yükleme
  Future<void> _loadBooks() async {
    final books = await libraryService.bookDao
        .getAllBooks(); // LibraryService üzerinden kitapları al
    setState(() {
      bookIds = books.map((book) => book.id).toList(); // Kitap ID'lerini al
      bookNames =
          books.map((book) => book.title).toList(); // Kitap isimlerini al
    });
  }

  // Loan (ödünç) ekleme
  Future<void> _addLoan() async {
    if (selectedUser == null || selectedBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir kullanıcı ve kitap seçin')),
      );
      return;
    }

    try {
      // Kitap ödünç verme işlemi
      await libraryService.borrowBook(selectedUser!.id, selectedBookId!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kitap başarıyla ödünç verildi')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ödünç Verme')),
      body: Row(
        children: [
          // Sol tarafta arama ve filtreleme kısmı
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanıcı seçimi
                  DropdownButton<CustomUser>(
                    value: selectedUser,
                    hint: Text('Kullanıcı Seçin'),
                    onChanged: (CustomUser? newUser) {
                      setState(() {
                        selectedUser = newUser;
                      });
                    },
                    items: users.map((CustomUser user) {
                      return DropdownMenuItem<CustomUser>(
                        value: user,
                        child: Text('${user.firstname} ${user.lastname}'),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Kitap seçimi
                  DropdownButton<String>(
                    value: selectedBookId,
                    hint: Text('Kitap Seçin'),
                    onChanged: (String? newBookId) {
                      setState(() {
                        selectedBookId = newBookId;
                      });
                    },
                    items: bookIds.map((bookId) {
                      int index = bookIds.indexOf(bookId);
                      selectedBookName = bookNames[index];
                      return DropdownMenuItem<String>(
                        value: bookId,
                        child: Text(bookNames[
                            index]), // Kitap adını burada gösteriyoruz
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Ödünç verme butonu
                  ElevatedButton(
                    onPressed: _addLoan,
                    child: Text('Ödünç Ver'),
                  ),
                ],
              ),
            ),
          ),

          // Sağ tarafta seçilen kitap ve kullanıcı bilgileri
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: selectedUser == null
                  ? Center(child: Text('Bir kullanıcı seçin'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seçilen Kullanıcı:'),
                        Text(
                            '${selectedUser!.firstname} ${selectedUser!.lastname}'),
                        SizedBox(height: 16),
                        Text('Seçilen Kitap:'),
                        Text(
                            '${selectedBookId != null ? bookNames[bookIds.indexOf(selectedBookId!)] : "Seçilmedi"}'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

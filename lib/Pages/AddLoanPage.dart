import 'package:flutter/material.dart';
import 'package:libris/Service/DatabaseHelper.dart';
import 'package:libris/Service/UserDao.dart';
import 'package:libris/Class/CustomUser.dart';
import 'package:libris/Class/Loan.dart';
import 'package:libris/Service/BookDao.dart'; // Kitapları getiren bir servis
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AddLoanPage extends StatefulWidget {
  @override
  _AddLoanPageState createState() => _AddLoanPageState();
}

class _AddLoanPageState extends State<AddLoanPage> {
  final UserDao userDao = UserDao();
  final BookDao bookDao = BookDao(); // BookDao servisi
  List<CustomUser> users = [];
  List<String> bookIds = []; // Kitap ID'leri listesi
  List<String> bookNames = []; // Kitap isimleri listesi
  CustomUser? selectedUser;
  String? selectedBookId;
  String? selectedBookName;
  DateTime loanDate = DateTime.now();
  DateTime? returnDate;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadBooks(); // Kitapları yükleme
  }

  // Kullanıcıları yükleme
  Future<void> _loadUsers() async {
    users = await userDao.getAllUsers();
    setState(() {});
  }

  // Kitapları yükleme
  Future<void> _loadBooks() async {
    final books = await bookDao.getAllBooks(); // BookDao üzerinden kitapları al
    setState(() {
      bookIds = books.map((book) => book.id).toList(); // Kitap ID'lerini al
      bookNames =
          books.map((book) => book.title).toList(); // Kitap isimlerini al
    });
  }

  // Kitap ödünç verme işlemi
  Future<void> _addLoan() async {
    if (selectedUser == null || selectedBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir kullanıcı ve kitap seçin')),
      );
      return;
    }

    final loanId = DateTime.now()
        .millisecondsSinceEpoch
        .toString(); // Loan için benzersiz ID
    final loan = Loan(
      userFirstName: selectedUser!.firstname,
      bookName: selectedBookName!,
      userLastName: selectedUser!.lastname,
      id: loanId,
      bookId: selectedBookId!,
      userId: selectedUser!.id,
      loanDate: loanDate,
      returnDate: returnDate,
    );

    // Loan verisini veritabanına ekle
    final db = await DatabaseHelper().database;
    await db.insert('loans', loan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    // Kullanıcının ödünç alınan kitap listesine kitap ID'sini ekle
    selectedUser!.borrowedBooksIds.add(loan.id);

    // Kullanıcıyı güncelle
    await userDao.updateUser(selectedUser!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kitap başarıyla ödünç verildi')),
    );

    Navigator.pop(context);
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

                  // Ödünç verme tarihi
                  ListTile(
                    title: Text('Ödünç Verme Tarihi: ${loanDate.toLocal()}'),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: loanDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null && pickedDate != loanDate) {
                        setState(() {
                          loanDate = pickedDate;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16),

                  // İade tarihi
                  ListTile(
                    title: Text(
                        'İade Tarihi: ${returnDate?.toLocal() ?? 'Belirtilmedi'}'),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: returnDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null && pickedDate != returnDate) {
                        setState(() {
                          returnDate = pickedDate;
                        });
                      }
                    },
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
                        SizedBox(height: 16),
                        Text('Ödünç Verme Tarihi: ${loanDate.toLocal()}'),
                        SizedBox(height: 16),
                        Text(
                            'İade Tarihi: ${returnDate?.toLocal() ?? 'Belirtilmedi'}'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

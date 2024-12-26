import 'package:flutter/material.dart';
import 'package:libris/Class/CustomBook.dart';
import 'package:libris/Class/CustomUser.dart';
import 'package:libris/Class/Loan.dart';
import 'package:libris/Service/BookDao.dart';
import 'package:libris/Service/DatabaseHelper.dart';
import 'package:libris/Service/LibraryService.dart';
import 'package:libris/Service/UserDao.dart';

class LoanDetailsPage extends StatelessWidget {
  final Loan loan;
  final CustomBook book;
  final CustomUser user;

  LoanDetailsPage({
    required this.loan,
    required this.book,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ödünç Detayları'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kullanıcı Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Ad: ${user.firstname} ${user.lastname}'),
            Text('Kullanıcı ID: ${user.id}'),
            SizedBox(height: 16),
            Text(
              'Kitap Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Kitap Adı: ${book.title}'),
            Text('Yazar: ${book.authors.join(', ')}'),
            Text('Yayınevi: ${book.publisher}'),
            Text('Sayfa Sayısı: ${book.pageCount}'),
            SizedBox(height: 16),
            Text(
              'Ödünç Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Ödünç Alınan Tarih: ${loan.loanDate.toLocal()}'),
            if (loan.returnDate != null)
              Text('Teslim Tarihi: ${loan.returnDate!.toLocal()}'),
            if (loan.returnDate == null)
              Text('Teslim Tarihi: Henüz teslim edilmedi'),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final confirmed = await _showConfirmationDialog(context);
                  if (confirmed) {
                    await _handleReturn(context);
                  }
                },
                child: Text('Teslim Al'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReturn(context) async {
    LibraryService().returnBook(loan.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kitap başarıyla teslim alındı')),
    );

    Navigator.pop(context, true);
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Teslim Al'),
              content:
                  Text('Bu kitabı teslim almak istediğinize emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Hayır'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Evet'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

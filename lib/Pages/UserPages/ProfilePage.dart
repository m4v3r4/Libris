import 'package:flutter/material.dart';
import 'package:libris/Class/CustomBook.dart';
import 'package:libris/Class/CustomUser.dart'; // CustomUser sınıfı
import 'package:libris/Class/Loan.dart';
import 'package:libris/Pages/LoanPages/LoanDetailPage.dart';
import 'package:libris/Service/LibraryService.dart'; // Kitap servisi

class ProfilePage extends StatefulWidget {
  final CustomUser user;

  ProfilePage({required this.user});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late LibraryService libraryService;
  List<Loan> loans = []; // Ödünç alınan kitapları tutacak liste

  @override
  void initState() {
    super.initState();
    libraryService = LibraryService(); // Kitap servisini başlatıyoruz
    _getBorrowedBooks(); // Sayfa yüklendiğinde ödünç alınan kitapları çekiyoruz
  }

  // Kullanıcının ödünç aldığı kitapları getiren fonksiyon
  Future<void> _getBorrowedBooks() async {
    try {
      // Kullanıcının ödünç aldığı Loan'ları LibraryService üzerinden alıyoruz
      List<Loan> fetchedLoans =
          await libraryService.getLoansByIds(widget.user.id);

      // Kitapları güncelliyoruz
      setState(() {
        loans = fetchedLoans; // loans listesini güncelliyoruz
      });
    } catch (e) {
      print('Error getting borrowed books: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Kullanıcı bilgilerini göster
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(widget.user.studentId ??
                  'https://via.placeholder.com/150'), // Profil resmi
            ),
            SizedBox(height: 16),
            Text(
              '${widget.user.firstname} ${widget.user.lastname}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Email: ${widget.user.email}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Telefon: ${widget.user.phoneNumber}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Öğrenci ID: ${widget.user.studentId ?? "Belirtilmemiş"}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Fakülte: ${widget.user.faculty ?? "Belirtilmemiş"}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Bölüm: ${widget.user.department ?? "Belirtilmemiş"}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Divider(),

            // Geçmiş ödünç kitaplarını listeleme
            Text(
              'Geçmiş Ödünç Alımlar:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            loans.isEmpty
                ? Center(child: CircularProgressIndicator()) // Yükleniyor
                : loans.isNotEmpty
                    ? Expanded(
                        // Expanded ile listView içinde kaydırma düzgün çalışır
                        child: ListView.builder(
                          itemCount: loans.length,
                          itemBuilder: (context, index) {
                            final loan = loans[index];
                            return ListTile(
                              onTap: () async {
                                // LoanDetailsPage'e geçerken doğru user'ı geçiyoruz
                                CustomBook? book = await LibraryService()
                                    .getBookById(loan.bookId);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoanDetailsPage(
                                      loan: loan,
                                      book:
                                          book!, // Eğer book nesnesi farklıysa, uygun değişiklik yapın
                                      user: widget
                                          .user, // widget.user doğru kullanıcıyı gönderiyor
                                    ),
                                  ),
                                );
                              },
                              title: Text(
                                  "${loan.bookName} (${loan.loanDate.toString().substring(0, 10)} - ${loan.returnDate?.toString().substring(0, 10) ?? 'Henüz İade Edilmedi'})"),
                              leading: Icon(Icons.book), // Kitap ikonu
                              trailing: loan.returnDate == null
                                  ? Text("İade Edilmedi")
                                  : Text(
                                      "İade: ${loan.returnDate!.toString().substring(0, 16)}"),
                            );
                          },
                        ),
                      )
                    : Center(child: Text('Henüz ödünç alınan kitap yok.')),
          ],
        ),
      ),
    );
  }
}

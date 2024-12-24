import 'package:flutter/material.dart';
import 'package:libris/Pages/AddLoanPage.dart';
import 'package:libris/Pages/BookPages/BooksPage.dart';
import 'package:libris/Pages/LoanListPage.dart';
import 'package:libris/Pages/UserPages/UsersPage.dart';
import 'package:libris/Service/BookDao.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    // TODO: implement initState
    load();
    super.initState();
  }

  final BookDao _bookDao = BookDao();
  int bookcount = 0;

  double _bookPosition = 0.0; // Kitap pozisyonu
  double _libraryPosition = 0.0; // Kitaplık pozisyonu

  load() async {
    bookcount = await _bookDao.getBooksCount();

    setState(() {
      bookcount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Libris Kütüphane Yönetimi'),
      ),
      body: Row(
        children: [
          // Sol taraftaki işlemler menüsü
          Expanded(
            flex: 4,
            child: Container(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text('Kitaplar'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BooksPage(),
                          ));
                    },
                  ),
                  ListTile(
                    title: Text('Ödünç Verilenler'),
                    onTap: () {
                      // Ödünç verme sayfasına yönlendir
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoanListPage(),
                          ));
                    },
                  ),
                  ListTile(
                    title: Text('Ödünç Ver'),
                    onTap: () {
                      // Ödünç verme sayfasına yönlendir
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddLoanPage(),
                          ));
                    },
                  ),
                  ListTile(
                    title: Text('Kullanıcılar'),
                    onTap: () {
                      // Kullanıcılar sayfasına yönlendir
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UsersPage(),
                          ));
                    },
                  ),
                  ListTile(
                    title: Text('Ayarlar'),
                    onTap: () {
                      // Ayarlara yönlendir
                    },
                  ),
                ],
              ),
            ),
          ),

          // Sağ taraftaki genel durum paneli
          Expanded(
            flex: 6,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Genel Durum',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  // Kitaplık animasyonu
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Kitaplık tıklanabilir
                          print('Kitaplık tıklandı');
                        },
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _libraryPosition =
                                  10.0; // Kitaplık animasyonunu başlat
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _libraryPosition = 0.0; // Kitaplık geri dönsün
                            });
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            transform: Matrix4.translationValues(
                                _libraryPosition, 0, 0),
                            child: Icon(
                              Icons.local_library,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Toplam Kitap: ' + bookcount.toString(),
                          style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Kitap animasyonu
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Kitap tıklanabilir
                          print('Kitap tıklandı');
                        },
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _bookPosition = 10.0; // Kitap animasyonunu başlat
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _bookPosition = 0.0; // Kitap geri dönsün
                            });
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            transform:
                                Matrix4.translationValues(_bookPosition, 0, 0),
                            child: Icon(
                              Icons.book,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Toplam Kullanıcı: 45',
                          style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 30),
                      SizedBox(width: 10),
                      Text('Ödünç Alınan Kitaplar: 30',
                          style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

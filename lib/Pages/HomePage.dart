import 'package:flutter/material.dart';
import 'package:libris/Pages/BookPages/BooksPage.dart';
import 'package:libris/Pages/LoanPages/AddLoanPage.dart';
import 'package:libris/Pages/LoanPages/LoanListPage.dart';
import 'package:libris/Pages/SettingsPage.dart';
import 'package:libris/Pages/UserPages/UsersPage.dart';
import 'package:libris/Service/BookDao.dart';
import 'package:libris/Service/LoanDao.dart';
import 'package:libris/Service/UserDao.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    load();
    super.initState();
  }

  int bookcount = 0;
  int usercount = 0;
  int loancount = 0;

  load() async {
    bookcount = await BookDao().getBooksCount();
    usercount = await UserDao().getUserCount();
    loancount = await LoanDao().getLoanCount();

    setState(() {
      bookcount;
      usercount;
      loancount;
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
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoanListPage(),
                          ));
                    },
                  ),
                  ListTile(
                    title: Text('Kullanıcılar'),
                    onTap: () {
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
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsPage(),
                          ));
                      // Ayarlara yönlendir
                    },
                  ),
                  Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddLoanPage(),
                                  ));
                            },
                            child: Column(
                              children: [
                                Icon(Icons.book),
                                Text("Kitap Ödünç Ver"),
                              ],
                            )),
                      ),
                      Expanded(
                        child: ElevatedButton(
                            onPressed: () {},
                            child: Column(
                              children: [
                                Icon(Icons.book),
                                Text("Kitap Teslim Al"),
                              ],
                            )),
                      ),
                    ],
                  )
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
                  SizedBox(height: 20),

                  InkWell(
                    onTap: () async {
                      await launch("https://sberkayu.com.tr");
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white, width: 2), // Beyaz kenarlık
                        borderRadius:
                            BorderRadius.circular(1), // Yuvarlatılmış köşeler
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2), // Hafif gölge
                            offset: Offset(4, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'lib/assets/libris-anim-white.gif',
                        fit: BoxFit.cover,
                        scale: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  Text(
                    'Genel Durum',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Kitap sayaç animasyonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_library, size: 50),
                      SizedBox(width: 10),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: bookcount),
                        duration: Duration(seconds: 2),
                        builder: (context, value, child) {
                          return Text(
                            'Toplam Kitap: $value',
                            style: TextStyle(fontSize: 18),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Kullanıcı sayaç animasyonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_circle, size: 50),
                      SizedBox(width: 10),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: usercount),
                        duration: Duration(seconds: 2),
                        builder: (context, value, child) {
                          return Text(
                            'Toplam Kullanıcı: $value',
                            style: TextStyle(fontSize: 18),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Ödünç alınan kitaplar sayaç animasyonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cached, size: 30),
                      SizedBox(width: 10),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: loancount),
                        duration: Duration(seconds: 2),
                        builder: (context, value, child) {
                          return Text(
                            'Kitap Hareketleri: $value',
                            style: TextStyle(fontSize: 18),
                          );
                        },
                      ),
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

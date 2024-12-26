import 'package:flutter/material.dart';
import 'package:libris/Class/CustomBook.dart';
import 'package:libris/Pages/BookPages/AddBookPage.dart';
import 'package:libris/Pages/BookPages/BookDetailsPage.dart';
import 'package:libris/Pages/BookPages/EditBookPage.dart';
import 'package:libris/Service/BookDao.dart';
import 'package:libris/Service/LibraryService.dart';

class BooksPage extends StatefulWidget {
  @override
  _BooksPageState createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final BookDao _bookDao = BookDao();

  List<CustomBook> books = [];
  List<CustomBook> filteredBooks = [];
  String searchQuery = '';
  String selectedAuthor = '';
  String selectedPublisher = '';
  String selectedYear = '';

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  // Kitapları yükleme
  Future<void> loadBooks() async {
    final allBooks = await _bookDao.getAllBooks();
    setState(() {
      books = allBooks;
      filteredBooks = allBooks; // İlk başta tüm kitapları göster
    });
  }

  // Arama ve filtreleme işlemi
  void filterBooks() {
    List<CustomBook> tempBooks = books;

    // Arama filtresi
    if (searchQuery.isNotEmpty) {
      tempBooks = tempBooks
          .where((book) =>
              book.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              book.authors.any((author) =>
                  author.toLowerCase().contains(searchQuery.toLowerCase())))
          .toList();
    }

    // Yazar filtresi
    if (selectedAuthor.isNotEmpty) {
      tempBooks = tempBooks
          .where((book) => book.authors.any((author) =>
              author.toLowerCase().contains(selectedAuthor.toLowerCase())))
          .toList();
    }

    // Yayınevi filtresi
    if (selectedPublisher.isNotEmpty) {
      tempBooks = tempBooks
          .where((book) => book.publisher
              .toLowerCase()
              .contains(selectedPublisher.toLowerCase()))
          .toList();
    }

    // Yayın Yılı filtresi
    if (selectedYear.isNotEmpty) {
      tempBooks = tempBooks
          .where((book) =>
              book.publishedDate.contains(selectedYear)) // Yıl filtresi
          .toList();
    }

    setState(() {
      filteredBooks = tempBooks;
    });
  }

  void handleMenuItem(String value) {
    switch (value) {
      case 'add':
        // Yeni kitap ekleme işlemi
        print('Yeni kitap ekle');
        break;
      case 'delete':
        // Kitap silme işlemi
        print('Kitap sil');
        break;
      // Diğer işlemler burada tanımlanabilir
      default:
        break;
    }
  }

  Future<void> navigateToAddBookPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddBookPage()),
    );

    // Eğer dönen sonuç 'true' ise listeyi yenile
    if (result == true) {
      setState(() {
        // Kitap listesini yeniden yüklemek için gereken işlemleri burada yapın
        loadBooks();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kitaplar'),
        actions: [
          PopupMenuButton<String>(
            onSelected: handleMenuItem,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  onTap: () {
                    navigateToAddBookPage();
                  },
                  value: 'add',
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Yeni Kitap Ekle'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Sol kısım: Arama ve filtreleme kısmı
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Arama kutusu
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Arama',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Yazar filtresi
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        selectedAuthor = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Yazar',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Yayınevi filtresi
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        selectedPublisher = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Yayınevi',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Yayın Yılı filtresi
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Yayın Yılı',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Arama butonu
                  ElevatedButton(
                    onPressed: filterBooks,
                    child: Text('Ara'),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            // Sağ kısım: Kitapların listesi
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtrelenmiş kitapları listeleme
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: filteredBooks[index].thumbnail.isNotEmpty
                              ? Image.network(
                                  filteredBooks[index].thumbnail,
                                  width: 40,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.book),
                          title: Text(filteredBooks[index].title),
                          subtitle: Text(
                            'Yazar: ${filteredBooks[index].authors.join(', ')}\nYayınevi: ${filteredBooks[index].publisher}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditBookPage(
                                              book: filteredBooks[index]),
                                        ));
                                  },
                                  icon: Icon(Icons.edit)),
                              IconButton(
                                onPressed: () async {
                                  // Silme işlemi için onay diyalogu
                                  bool? confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Kitap Silme'),
                                        content: Text(
                                            'Bu kitabı silmek istediğinizden emin misiniz?'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(
                                                  false); // Silme işlemini iptal et
                                            },
                                            child: Text('Hayır'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(
                                                  true); // Silme işlemini onayla
                                            },
                                            child: Text('Evet'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  // Eğer kullanıcı silmeyi onaylarsa
                                  if (confirmDelete == true) {
                                    // Kitap silme işlemini başlat
                                    await LibraryService()
                                        .bookDao
                                        .deleteBook(filteredBooks[index].id);
                                    setState(() {
                                      loadBooks();
                                    });

                                    // Silme işlemi başarılı, kullanıcıya bildirim yap
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Kitap başarıyla silindi.')),
                                    );
                                  } else {
                                    // Kullanıcı silmeyi iptal etti
                                    print('Silme işlemi iptal edildi.');
                                  }
                                },
                                icon: Icon(Icons.delete),
                              )
                            ],
                          ),
                          onTap: () {
                            // Kitap tıklandığında yapılacak işlem
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookDetailsPage(
                                      book: filteredBooks[index]),
                                ));
                            print(
                                'Kitap tıklandı: ${filteredBooks[index].title}');
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

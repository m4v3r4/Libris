import 'package:flutter/material.dart';
import 'package:libris/Class/CustomBook.dart';
import 'package:libris/Service/BookDao.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddBookPage extends StatefulWidget {
  @override
  _AddBookPageState createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final BookDao _bookDao = BookDao();

  // Kitap formu için gerekli olan kontrolcüler
  final TextEditingController isbnController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorsController = TextEditingController();
  final TextEditingController publisherController = TextEditingController();
  final TextEditingController publishedDateController = TextEditingController();
  final TextEditingController pageCountController = TextEditingController();
  final TextEditingController shelfController = TextEditingController();
  final TextEditingController rackController = TextEditingController();

  bool isAvailable = true; // Kitap mevcut mu?
  String bookThumbnail = ''; // Kitap resmi

  // Google Books API'den kitap bilgilerini al
  Future<void> fetchBookDetails(String isbn) async {
    final url = 'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['items'] != null) {
        final volumeInfo = data['items'][0]['volumeInfo'];

        setState(() {
          titleController.text = volumeInfo['title'] ?? 'Bilinmeyen Başlık';
          authorsController.text =
              (volumeInfo['authors'] ?? ['Bilinmeyen Yazar']).join(', ');
          publisherController.text =
              volumeInfo['publisher'] ?? 'Bilinmeyen Yayıncı';
          publishedDateController.text =
              volumeInfo['publishedDate'] ?? 'Tarih yok';
          pageCountController.text = (volumeInfo['pageCount'] ?? 0).toString();
          bookThumbnail =
              volumeInfo['imageLinks']?['thumbnail'] ?? ''; // Kitap resmi
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Kitap bulunamadı!')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('API hatası!')));
    }
  }

  // Kitap ekleme işlemi
  Future<void> addBook() async {
    final newBook = CustomBook(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text,
      authors: authorsController.text.split(','),
      description: 'Açıklama yok',
      thumbnail: bookThumbnail.isNotEmpty
          ? bookThumbnail
          : 'https://via.placeholder.com/128x192',
      publisher: publisherController.text,
      publishedDate: publishedDateController.text,
      pageCount: int.tryParse(pageCountController.text) ?? 0,
      shelf: shelfController.text,
      rack: rackController.text,
      isAvailable: isAvailable ? 1 : 0,
      currentUserId: null,
      isbn: isbnController.text,
    );

    await _bookDao.insertBook(newBook);

    // Başarılı ekleme sonrası liste sayfasına geri dön
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Kitap Ekle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Row(
            children: [
              // Sol Kısım: Form Alanları
              Expanded(
                flex: 1,
                child: Card(
                  elevation: 5,
                  margin: EdgeInsets.only(right: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ISBN
                        TextField(
                          controller: isbnController,
                          decoration: InputDecoration(
                            labelText: 'ISBN',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (isbn) {
                            if (isbn.isNotEmpty) {
                              fetchBookDetails(
                                  isbn); // ISBN girildiğinde Google Books'tan veri çek
                            }
                          },
                        ),
                        SizedBox(height: 16),

                        // Kitap Başlığı
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Kitap Başlığı',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Yazarlar
                        TextField(
                          controller: authorsController,
                          decoration: InputDecoration(
                            labelText: 'Yazarlar (Virgül ile ayırın)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Yayıncı
                        TextField(
                          controller: publisherController,
                          decoration: InputDecoration(
                            labelText: 'Yayınevi',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Yayın Yılı
                        TextField(
                          controller: publishedDateController,
                          decoration: InputDecoration(
                            labelText: 'Yayın Yılı',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Sayfa Sayısı
                        TextField(
                          controller: pageCountController,
                          decoration: InputDecoration(
                            labelText: 'Sayfa Sayısı',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 16),

                        // Dolap
                        TextField(
                          controller: shelfController,
                          decoration: InputDecoration(
                            labelText: 'Dolap',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Raf
                        TextField(
                          controller: rackController,
                          decoration: InputDecoration(
                            labelText: 'Raf',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Kitap Durumu
                        Row(
                          children: [
                            Text('Mevcut:'),
                            Checkbox(
                              value: isAvailable,
                              onChanged: (bool? value) {
                                setState(() {
                                  isAvailable = value!;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Kitap Ekleme Butonu
                        ElevatedButton(
                          onPressed: addBook,
                          child: Text('Kitap Ekle'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Sağ Kısım: Kitap Resmi

              Expanded(
                flex: 1,
                child: Card(
                  margin: EdgeInsets.all(300),
                  elevation: 5,
                  child: bookThumbnail.isNotEmpty
                      ? Image.network(
                          bookThumbnail,
                          fit: BoxFit.fill,
                        )
                      : Icon(Icons.book),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

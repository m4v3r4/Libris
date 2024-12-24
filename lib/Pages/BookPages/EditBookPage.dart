import 'package:flutter/material.dart';
import 'package:libris/Class/CustomBook.dart';
import 'package:libris/Service/BookDao.dart';

class EditBookPage extends StatefulWidget {
  final CustomBook book; // Düzenlenecek kitap

  EditBookPage({required this.book});

  @override
  _EditBookPageState createState() => _EditBookPageState();
}

class _EditBookPageState extends State<EditBookPage> {
  final BookDao _bookDao = BookDao();

  // Kitap formu için gerekli olan kontrolcüler
  late TextEditingController isbnController;
  late TextEditingController titleController;
  late TextEditingController authorsController;
  late TextEditingController publisherController;
  late TextEditingController publishedDateController;
  late TextEditingController pageCountController;
  late TextEditingController shelfController;
  late TextEditingController rackController;

  bool isAvailable = true; // Kitap mevcut mu?
  String bookThumbnail = ''; // Kitap resmi

  @override
  void initState() {
    super.initState();
    // Form alanlarını mevcut kitap bilgileriyle dolduruyoruz
    isbnController = TextEditingController(text: widget.book.isbn);
    titleController = TextEditingController(text: widget.book.title);
    authorsController =
        TextEditingController(text: widget.book.authors.join(', '));
    publisherController = TextEditingController(text: widget.book.publisher);
    publishedDateController =
        TextEditingController(text: widget.book.publishedDate);
    pageCountController =
        TextEditingController(text: widget.book.pageCount.toString());
    shelfController = TextEditingController(text: widget.book.shelf);
    rackController = TextEditingController(text: widget.book.rack);

    // Kitabın mevcut durumu
    isAvailable = widget.book.isAvailable == 1;
    bookThumbnail = widget.book.thumbnail;
  }

  // Kitap düzenleme işlemi
  Future<void> updateBook() async {
    final updatedBook = CustomBook(
      id: widget.book.id,
      title: titleController.text,
      authors: authorsController.text.split(','),
      description: widget.book.description, // Güncelleme yapılmadı
      thumbnail: bookThumbnail.isNotEmpty
          ? bookThumbnail
          : 'https://via.placeholder.com/128x192',
      publisher: publisherController.text,
      publishedDate: publishedDateController.text,
      pageCount: int.tryParse(pageCountController.text) ?? 0,
      shelf: shelfController.text,
      rack: rackController.text,
      isAvailable: isAvailable ? 1 : 0,
      currentUserId: widget.book.currentUserId,
      isbn: isbnController.text,
    );

    await _bookDao.updateBook(updatedBook);

    // Başarılı güncelleme sonrası liste sayfasına geri dön
    Navigator.pop(context, updatedBook);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kitap Düzenle'),
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

                        // Kitap Düzenleme Butonu
                        ElevatedButton(
                          onPressed: updateBook,
                          child: Text('Kitap Düzenle'),
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
                  margin: EdgeInsets.all(8),
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

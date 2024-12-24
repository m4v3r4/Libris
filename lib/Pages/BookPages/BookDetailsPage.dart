import 'package:flutter/material.dart';
import 'package:libris/Class/CustomBook.dart';

class BookDetailsPage extends StatelessWidget {
  final CustomBook book; // CustomBook objesini alıyoruz

  // Constructor
  BookDetailsPage({required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Kitap Kapağı
                Image.network(book.thumbnail),
                SizedBox(height: 10),
                // Kitap Başlığı
                Text(
                  book.title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                // Kitap Yazarları
                Text(
                  'Yazar(lar): ${book.authors.join(', ')}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),

                // Kitap Açıklaması
                Text(
                  'Açıklama: ${book.description}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),

                // Kitap Yayıncı
                Text(
                  'Yayıncı: ${book.publisher}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),

                // Kitap Yayınlanma Tarihi
                Text(
                  'Yayınlanma Tarihi: ${book.publishedDate}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),

                // Kitap Sayfa Sayısı
                Text(
                  'Sayfa Sayısı: ${book.pageCount}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),

                // Kitap ISBN
                Text(
                  'ISBN: ${book.isbn}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),

                // Kitap Mevcudiyet Durumu
                Text(
                  'Kütüphanede Mi? ${book.isAvailable == 1 ? 'Evet' : 'Hayır'}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),

                // Kitap Ödünç Alan Kullanıcı (varsa)
                if (book.currentUserId != null)
                  Text(
                    'Ödünç Alan Kullanıcı: ${book.currentUserId}',
                    style: TextStyle(fontSize: 16),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

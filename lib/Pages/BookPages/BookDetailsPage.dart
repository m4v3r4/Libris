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
        title: Text(
          book.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kitap Kapağı
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    book.thumbnail,
                    height: 200,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Kitap Başlık ve Yazarlar
              Center(
                child: Column(
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Yazar(lar): ${book.authors.join(', ')}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Kitap Detay Kartı
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Açıklama:', book.description),
                      _buildDetailRow('Yayıncı:', book.publisher),
                      _buildDetailRow('Yayınlanma Tarihi:', book.publishedDate),
                      _buildDetailRow('Sayfa Sayısı:', '${book.pageCount}'),
                      _buildDetailRow('ISBN:', book.isbn),
                      _buildDetailRow(
                        'Kütüphanede Mi?',
                        book.isAvailable == 1 ? 'Evet' : 'Hayır',
                      ),
                      if (book.currentUserId != null)
                        _buildDetailRow(
                          'Ödünç Alan Kullanıcı:',
                          book.currentUserId!,
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Detay satırını oluşturan widget
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}

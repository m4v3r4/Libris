import 'package:flutter/material.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:libris/features/books/screen/book_form_screen.dart';
import 'package:libris/features/books/services/book_service.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BookService _bookService = BookService();
  late Book _book;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
  }

  Future<void> _refreshBook() async {
    final updated = await _bookService.getBookById(_book.id!);
    if (updated != null) {
      setState(() => _book = updated);
    }
  }

  Future<void> _editBook() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookFormScreen(book: _book)),
    );
    await _refreshBook();
  }

  Future<void> _deleteBook() async {
    await _bookService.deleteBook(_book.id!);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Detayı'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editBook),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteBook),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _header(context),
            const SizedBox(height: 24),
            _infoTile('Yazar', _book.author),
            _infoTile('Açıklama', _book.description),
            _infoTile(
              'Durum',
              _book.isAvailable ? 'Müsait' : 'Emanette',
              valueColor: _book.isAvailable ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_book.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Chip(
          label: Text(_book.isAvailable ? 'Müsait' : 'Emanette'),
          backgroundColor: _book.isAvailable
              ? Colors.green.shade100
              : Colors.red.shade100,
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, color: valueColor)),
        ],
      ),
    );
  }
}

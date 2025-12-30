import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';

class BookFormScreen extends StatefulWidget {
  final Book? book;

  const BookFormScreen({super.key, this.book});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookService = DatabaseHelper.instance;

  late bool _isEditing;
  late bool _isAvailable;

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _isbnController = TextEditingController();
  final _publisherController = TextEditingController();
  final _publishYearController = TextEditingController();
  final _pageCountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.book != null;

    if (_isEditing) {
      final book = widget.book!;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _descriptionController.text = book.description;
      _isbnController.text = book.isbn ?? '';
      _publisherController.text = book.publisher ?? '';
      _publishYearController.text = book.publishYear?.toString() ?? '';
      _pageCountController.text = book.pageCount?.toString() ?? '';
      _categoryController.text = book.category ?? '';
      _locationController.text = book.location ?? '';
      _isAvailable = book.isAvailable;
    } else {
      _isAvailable = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _publishYearController.dispose();
    _pageCountController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    final book = Book(
      id: _isEditing ? widget.book!.id : null,
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      description: _descriptionController.text.trim(),
      isbn: _isbnController.text.trim().isEmpty
          ? null
          : _isbnController.text.trim(),
      publisher: _publisherController.text.trim().isEmpty
          ? null
          : _publisherController.text.trim(),
      publishYear: _publishYearController.text.isEmpty
          ? null
          : int.parse(_publishYearController.text),
      pageCount: _pageCountController.text.isEmpty
          ? null
          : int.parse(_pageCountController.text),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      isAvailable: _isAvailable,
    );

    if (_isEditing) {
      await _bookService.updateBook(book);
    } else {
      await _bookService.createBook(book);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Kitabı Düzenle' : 'Yeni Kitap Ekle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(_titleController, 'Kitap Adı'),
            _buildTextField(_authorController, 'Yazar'),
            _buildTextField(_descriptionController, 'Açıklama', maxLines: 3),
            _buildTextField(_isbnController, 'ISBN'),
            _buildTextField(_publisherController, 'Yayınevi'),
            _buildNumberField(_publishYearController, 'Basım Yılı'),
            _buildNumberField(_pageCountController, 'Sayfa Sayısı'),
            _buildTextField(_categoryController, 'Kategori'),
            _buildTextField(_locationController, 'Raf / Konum'),

            SwitchListTile(
              title: const Text('Müsait'),
              value: _isAvailable,
              onChanged: (value) {
                setState(() => _isAvailable = value);
              },
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveBook,
              child: Text(_isEditing ? 'Güncelle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if ((label == 'Kitap Adı' || label == 'Yazar') &&
              (value == null || value.isEmpty)) {
            return '$label boş olamaz';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

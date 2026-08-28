import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';

class CategoryBooksScreen extends StatefulWidget {
  final String categoryName;
  const CategoryBooksScreen({super.key, required this.categoryName});

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Book> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final books = await _databaseHelper.getBooksByCategory(
        widget.categoryName,
      );
      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _changeCategory(Book book) async {
    final categories = await _databaseHelper.getCategoryNames();
    categories.remove(widget.categoryName);

    if (!mounted) return;

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başka kategori bulunamadı.')),
      );
      return;
    }

    String? selectedCategory;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kategori Taşı'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Yeni Kategori Seçin'),
                value: selectedCategory,
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedCategory = value);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final category = selectedCategory;
                if (category == null) return;

                await _databaseHelper.updateBookCategory(book.id!, category);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (!mounted) return;
                await _loadBooks();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kitap "$category" kategorisine taşındı.'),
                  ),
                );
              },
              child: const Text('Taşı'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
          ? const Center(child: Text('Bu kategoride kitap yok.'))
          : ListView.separated(
              itemCount: _books.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final book = _books[index];
                return ListTile(
                  leading: const Icon(Icons.book, color: Colors.blueGrey),
                  title: Text(
                    book.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(book.author),
                  trailing: IconButton(
                    icon: const Icon(Icons.drive_file_move_outlined),
                    tooltip: 'Kategori Değiştir',
                    onPressed: () => _changeCategory(book),
                  ),
                );
              },
            ),
    );
  }
}

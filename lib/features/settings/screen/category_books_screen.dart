import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:libris/features/settings/services/category_service.dart';

class CategoryBooksScreen extends StatefulWidget {
  final String categoryName;
  const CategoryBooksScreen({super.key, required this.categoryName});

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  late CategoryService _categoryService;

  List<Book> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _categoryService = CategoryService(() => DatabaseHelper.instance.database);
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final books = await _databaseHelper.getBooksByCategory(
        widget.categoryName,
      );
      if (mounted) {
        setState(() {
          _books = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _changeCategory(Book book) async {
    // Tüm kategorileri çek
    final categories = await _categoryService.getCategoryNames();
    // Mevcut kategoriyi listeden çıkar (zaten orada)
    categories.remove(widget.categoryName);

    if (!mounted) return;

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başka kategori bulunamadı.')),
      );
      return;
    }

    String? selectedCategory;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kategori Taşı'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Yeni Kategori Seçin'),
                value: selectedCategory,
                items: categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  setState(() => selectedCategory = val);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCategory != null) {
                  await _databaseHelper.updateBookCategory(
                    book.id!,
                    selectedCategory!,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _loadBooks(); // Listeyi yenile (taşınan kitap listeden gidecek)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Kitap "$selectedCategory" kategorisine taşındı.',
                        ),
                      ),
                    );
                  }
                }
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

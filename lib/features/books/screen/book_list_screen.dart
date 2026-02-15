import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:libris/features/books/screen/book_detail_screen.dart';
import 'package:libris/features/books/screen/book_form_screen.dart';
import 'package:libris/features/books/widgets/book_item_widget.dart';

enum BookSortType { titleAsc, titleDesc, newest }

class BookListScreen extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onClose;

  const BookListScreen({super.key, this.embedded = false, this.onClose});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Book> _books = [];
  bool _isLoading = true;

  String _searchQuery = '';
  BookViewType _viewType = BookViewType.list;
  BookSortType _sortType = BookSortType.titleAsc;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    final books = await _databaseHelper.getBooks();
    setState(() {
      _books = books;
      _isLoading = false;
    });
  }

  List<Book> get _filteredBooks {
    final list = _books.where((book) {
      final query = _searchQuery.toLowerCase();
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);
    }).toList();

    switch (_sortType) {
      case BookSortType.titleAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case BookSortType.titleDesc:
        list.sort((a, b) => b.title.compareTo(a.title));
        break;
      case BookSortType.newest:
        list.sort((a, b) => b.id!.compareTo(a.id!));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.embedded
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
              )
            : null,
        title: widget.embedded ? null : const Text('Kitap Listesi'),
        actions: widget.embedded
            ? null
            : [
                IconButton(
                  icon: Icon(
                    _viewType == BookViewType.list
                        ? Icons.view_module
                        : Icons.view_list,
                  ),
                  onPressed: () {
                    setState(() {
                      _viewType = _viewType == BookViewType.list
                          ? BookViewType.card
                          : BookViewType.list;
                    });
                  },
                ),
                PopupMenuButton<BookSortType>(
                  onSelected: (value) {
                    setState(() => _sortType = value);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: BookSortType.titleAsc,
                      child: Text('A -> Z'),
                    ),
                    PopupMenuItem(
                      value: BookSortType.titleDesc,
                      child: Text('Z -> A'),
                    ),
                    PopupMenuItem(
                      value: BookSortType.newest,
                      child: Text('En Yeni'),
                    ),
                  ],
                ),
              ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Kitap veya yazar ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                ? const Center(child: Text('Sonuc bulunamadi'))
                : _viewType == BookViewType.list
                ? ListView.builder(
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      return BookItemWidget(
                        book: book,
                        viewType: _viewType,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookDetailScreen(book: book),
                            ),
                          );
                        },
                        onEdit: () => _navigateToEditBook(book),
                        onDelete: () => _deleteBook(book.id!),
                      );
                    },
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 1500
                          ? 5
                          : width >= 1200
                          ? 4
                          : width >= 800
                          ? 3
                          : 2;

                      return GridView.builder(
                        itemCount: _filteredBooks.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.9,
                        ),
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];
                          return BookItemWidget(
                            book: book,
                            viewType: _viewType,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookDetailScreen(book: book),
                                ),
                              );
                            },
                            onEdit: () => _navigateToEditBook(book),
                            onDelete: () => _deleteBook(book.id!),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddBook,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _navigateToAddBook() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookFormScreen()),
    );
    _loadBooks();
  }

  Future<void> _navigateToEditBook(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookFormScreen(book: book)),
    );
    _loadBooks();
  }

  Future<void> _deleteBook(int id) async {
    await _databaseHelper.deleteBook(id);
    _loadBooks();
  }
}


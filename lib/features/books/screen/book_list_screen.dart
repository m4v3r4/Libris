import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/common/widgets/section_toolbar.dart';
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
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    final books = await _databaseHelper.getBooks();
    if (!mounted) return;
    setState(() {
      _books = books;
      _isLoading = false;
    });
  }

  Future<void> _openBookDetail(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
    await _loadBooks();
  }

  List<Book> get _filteredBooks {
    final query = _searchQuery.trim().toLowerCase();
    final list = _books.where((book) {
      if (query.isEmpty) return true;
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          (book.isbn?.toLowerCase().contains(query) ?? false) ||
          (book.category?.toLowerCase().contains(query) ?? false) ||
          (book.location?.toLowerCase().contains(query) ?? false);
    }).toList();

    switch (_sortType) {
      case BookSortType.titleAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case BookSortType.titleDesc:
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case BookSortType.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return list;
  }

  String get _sortLabel {
    switch (_sortType) {
      case BookSortType.titleAsc:
        return 'A → Z';
      case BookSortType.titleDesc:
        return 'Z → A';
      case BookSortType.newest:
        return l10n('En yeni', 'Newest');
    }
  }

  void _close() {
    if (widget.embedded) {
      widget.onClose?.call();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBooks;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          SectionToolbar(
            title: l10n('Kitaplar', 'Books'),
            subtitle: l10n(
              'Katalog, konum ve müsaitlik bilgilerini yönetin.',
              'Manage catalog, location, and availability information.',
            ),
            icon: Icons.menu_book_rounded,
            count: filtered.length,
            onClose: _close,
            leadingIcon:
                widget.embedded ? Icons.close_rounded : Icons.arrow_back_rounded,
            leadingTooltip:
                widget.embedded ? l10n('Kapat', 'Close') : l10n('Geri', 'Back'),
            actions: [
              IconButton.filledTonal(
                onPressed: () {
                  setState(() {
                    _viewType = _viewType == BookViewType.list
                        ? BookViewType.card
                        : BookViewType.list;
                  });
                },
                icon: Icon(
                  _viewType == BookViewType.list
                      ? Icons.grid_view_rounded
                      : Icons.view_agenda_outlined,
                  size: 20,
                ),
                tooltip: _viewType == BookViewType.list
                    ? l10n('Kart görünümü', 'Card view')
                    : l10n('Liste görünümü', 'List view'),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<BookSortType>(
                tooltip: '${l10n('Sırala', 'Sort')}: $_sortLabel',
                initialValue: _sortType,
                onSelected: (value) => setState(() => _sortType = value),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: BookSortType.titleAsc,
                    child: Text(l10n('Başlık A → Z', 'Title A → Z')),
                  ),
                  PopupMenuItem(
                    value: BookSortType.titleDesc,
                    child: Text(l10n('Başlık Z → A', 'Title Z → A')),
                  ),
                  PopupMenuItem(
                    value: BookSortType.newest,
                    child: Text(l10n('En yeni eklenenler', 'Recently added')),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text(_sortLabel),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _loadBooks,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n('Yenile', 'Refresh'),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: scheme.surface.withValues(alpha: 0.45),
            child: SectionSearchField(
              controller: _searchController,
              hintText: l10n(
                'Başlık, yazar, ISBN, kategori veya konum ara...',
                'Search title, author, ISBN, category, or location...',
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? SectionEmptyState(
                        icon: _books.isEmpty
                            ? Icons.library_add_outlined
                            : Icons.search_off_rounded,
                        title: _books.isEmpty
                            ? l10n('Henüz kitap yok', 'No books yet')
                            : l10n(
                                'Aramanızla eşleşen kitap bulunamadı',
                                'No books match your search',
                              ),
                        description: _books.isEmpty
                            ? l10n(
                                'Kataloğu oluşturmaya ilk kitabınızı ekleyerek başlayın.',
                                'Start building your catalog by adding your first book.',
                              )
                            : l10n(
                                'Arama ifadesini değiştirin veya temizleyin.',
                                'Change or clear your search query.',
                              ),
                        actionLabel:
                            _books.isEmpty ? l10n('Kitap Ekle', 'Add Book') : null,
                        onAction: _books.isEmpty ? _navigateToAddBook : null,
                      )
                    : _viewType == BookViewType.list
                        ? ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final book = filtered[index];
                              return BookItemWidget(
                                book: book,
                                viewType: _viewType,
                                onTap: () => _openBookDetail(book),
                                onEdit: () => _navigateToEditBook(book),
                                onDelete: () => _confirmDeleteBook(book),
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
                                          : width >= 520
                                              ? 2
                                              : 1;

                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
                                itemCount: filtered.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.08,
                                ),
                                itemBuilder: (context, index) {
                                  final book = filtered[index];
                                  return BookItemWidget(
                                    book: book,
                                    viewType: _viewType,
                                    onTap: () => _openBookDetail(book),
                                    onEdit: () => _navigateToEditBook(book),
                                    onDelete: () => _confirmDeleteBook(book),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddBook,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n('Kitap Ekle', 'Add Book')),
      ),
    );
  }

  Future<void> _navigateToAddBook() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookFormScreen()),
    );
    await _loadBooks();
  }

  Future<void> _navigateToEditBook(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookFormScreen(book: book)),
    );
    await _loadBooks();
  }

  Future<void> _confirmDeleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n('Kitabı sil?', 'Delete book?')),
        content: Text(
          l10n(
            '“${book.title}” kaydı silinecek. Bu işlem geri alınamaz.',
            '“${book.title}” will be deleted. This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n('Vazgeç', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n('Sil', 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || book.id == null) return;
    await _databaseHelper.deleteBook(book.id!);
    await _loadBooks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n('Kitap silindi.', 'Book deleted.'))),
    );
  }
}

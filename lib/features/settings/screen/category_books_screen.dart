import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/common/widgets/section_toolbar.dart';
import 'package:libris/features/books/models/book.dart';

class CategoryBooksScreen extends StatefulWidget {
  final String categoryName;

  const CategoryBooksScreen({super.key, required this.categoryName});

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Book> _books = [];
  bool _isLoading = true;
  String _query = '';

  List<Book> get _filteredBooks {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _books;

    return _books.where((book) {
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          (book.isbn?.toLowerCase().contains(query) ?? false) ||
          (book.publisher?.toLowerCase().contains(query) ?? false) ||
          (book.location?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n('Kitaplar yüklenemedi: $e', 'Books could not be loaded: $e'),
          ),
        ),
      );
    }
  }

  Future<void> _changeCategory(Book book) async {
    final categories = await _databaseHelper.getCategoryNames();
    categories.remove(widget.categoryName);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (categories.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n(
              'Kitabı taşıyabileceğiniz başka bir kategori yok.',
              'There is no other category to move this book to.',
            ),
          ),
        ),
      );
      return;
    }

    String? selectedCategory;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.drive_file_move_outline),
                const SizedBox(width: 10),
                Text(l10n('Kategori Değiştir', 'Change Category')),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n(
                      'Şu an: ${widget.categoryName}',
                      'Current: ${widget.categoryName}',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: l10n('Yeni kategori', 'New category'),
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedCategory = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n('Vazgeç', 'Cancel')),
              ),
              FilledButton.icon(
                onPressed: selectedCategory == null
                    ? null
                    : () async {
                        final category = selectedCategory;
                        final id = book.id;
                        if (category == null || id == null) return;

                        await _databaseHelper.updateBookCategory(id, category);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);

                        if (!mounted) return;
                        await _loadBooks();
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n(
                                '“${book.title}” kitabı “$category” kategorisine taşındı.',
                                '“${book.title}” was moved to the “$category” category.',
                              ),
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.drive_file_move_rounded, size: 18),
                label: Text(l10n('Taşı', 'Move')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = _filteredBooks;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          SectionToolbar(
            title: widget.categoryName,
            subtitle: l10n(
              'Bu kategorideki kitapları görüntüleyin ve yeniden sınıflandırın.',
              'View and reclassify books in this category.',
            ),
            icon: Icons.menu_book_rounded,
            count: _books.length,
            onClose: () => Navigator.maybePop(context),
            leadingIcon: Icons.arrow_back_rounded,
            leadingTooltip: l10n('Geri', 'Back'),
            actions: [
              IconButton(
                onPressed: _isLoading ? null : _loadBooks,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n('Yenile', 'Refresh'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: SectionSearchField(
              controller: _searchController,
              hintText: l10n(
                'Kitap, yazar, ISBN, yayınevi veya konum ara...',
                'Search book, author, ISBN, publisher, or location...',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _books.isEmpty
                    ? SectionEmptyState(
                        icon: Icons.library_books_outlined,
                        title: l10n(
                          'Bu kategoride kitap yok',
                          'No books in this category',
                        ),
                        description: l10n(
                          'Kitaplar bu kategoriye atandığında burada listelenecek.',
                          'Books assigned to this category will appear here.',
                        ),
                      )
                    : books.isEmpty
                        ? SectionEmptyState(
                            icon: Icons.search_off_rounded,
                            title: l10n('Kitap bulunamadı', 'No books found'),
                            description: l10n(
                              'Arama ifadenizi değiştirerek tekrar deneyin.',
                              'Try changing your search query.',
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: books.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final book = books[index];
                              final details = <String>[
                                book.author,
                                if (book.publisher?.trim().isNotEmpty ?? false)
                                  book.publisher!.trim(),
                                if (book.location?.trim().isNotEmpty ?? false)
                                  '${l10n('Konum', 'Location')}: ${book.location!.trim()}',
                              ];

                              return Card(
                                margin: EdgeInsets.zero,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: scheme.primaryContainer.withValues(
                                        alpha: 0.55,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    book.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      details.join(' · '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: book.isAvailable
                                              ? scheme.primaryContainer
                                                  .withValues(alpha: 0.45)
                                              : scheme.errorContainer,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          book.isAvailable
                                              ? l10n('Müsait', 'Available')
                                              : l10n('Emanette', 'On loan'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: book.isAvailable
                                                    ? scheme.primary
                                                    : scheme.onErrorContainer,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.drive_file_move_outlined,
                                        ),
                                        tooltip: l10n(
                                          'Kategori Değiştir',
                                          'Change Category',
                                        ),
                                        onPressed: () => _changeCategory(book),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

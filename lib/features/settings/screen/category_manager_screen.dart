import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/common/widgets/section_toolbar.dart';
import 'package:libris/features/home/screens/widgets/category_analysis_widget.dart';
import 'package:libris/features/settings/screen/category_books_screen.dart';

class CategoryManagerScreen extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onClose;

  const CategoryManagerScreen({super.key, this.embedded = false, this.onClose});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final DatabaseHelper service = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _query = '';

  List<Map<String, dynamic>> get _filteredCategories {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _categories;

    return _categories.where((item) {
      final name = (item['name'] as String).toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data = await service.getCategoriesWithStats();
      if (!mounted) return;
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n('Kategoriler yüklenemedi: $e', 'Categories could not be loaded: $e'),
          ),
        ),
      );
    }
  }

  Future<void> _showFormDialog({int? id, String? currentName}) async {
    final controller = TextEditingController(text: currentName);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(id == null ? Icons.add_rounded : Icons.edit_rounded),
            const SizedBox(width: 10),
            Text(
              id == null
                  ? l10n('Kategori Ekle', 'Add Category')
                  : l10n('Kategori Düzenle', 'Edit Category'),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n('Kategori adı', 'Category name'),
              hintText: l10n('Örn. Roman, Tarih, Çocuk', 'E.g. Fiction, History, Children'),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveCategory(
              dialogContext,
              controller,
              id: id,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n('Vazgeç', 'Cancel')),
          ),
          FilledButton.icon(
            onPressed: () => _saveCategory(
              dialogContext,
              controller,
              id: id,
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(
              id == null ? l10n('Ekle', 'Add') : l10n('Kaydet', 'Save'),
            ),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> _saveCategory(
    BuildContext dialogContext,
    TextEditingController controller, {
    int? id,
  }) async {
    final name = controller.text.trim();
    if (name.isEmpty) return;

    try {
      if (id == null) {
        await service.addCategory(name);
      } else {
        await service.updateCategory(id, name);
      }

      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext);
      if (!mounted) return;
      await _loadData();
    } catch (e) {
      if (!dialogContext.mounted) return;
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text(
            l10n('Kategori kaydedilemedi: $e', 'Category could not be saved: $e'),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(int id, String name, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n('Kategoriyi sil?', 'Delete category?')),
        content: Text(
          count > 0
              ? l10n(
                  '“$name” kategorisinde $count kitap bulunuyor. Kategori kullanımdayken silinemeyebilir.',
                  'The “$name” category contains $count books. A category in use may not be deleted.',
                )
              : l10n(
                  '“$name” kategorisi silinecek. Bu işlem geri alınamaz.',
                  'The “$name” category will be deleted. This action cannot be undone.',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n('Vazgeç', 'Cancel')),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(l10n('Sil', 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _delete(id, name);
    }
  }

  Future<void> _delete(int id, String name) async {
    try {
      await service.deleteCategory(id, name);
      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n('“$name” kategorisi silindi.', 'The “$name” category was deleted.'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n('Kategori silinemedi', 'Category could not be deleted')),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n('Tamam', 'OK')),
            ),
          ],
        ),
      );
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
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredCategories;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            SectionToolbar(
              title: l10n('Kategoriler', 'Categories'),
              subtitle: l10n(
                'Koleksiyonu sınıflandırın ve kategori dağılımını inceleyin.',
                'Classify the collection and review category distribution.',
              ),
              icon: Icons.category_rounded,
              count: _categories.length,
              onClose: _close,
              leadingIcon:
                  widget.embedded ? Icons.close_rounded : Icons.arrow_back_rounded,
              leadingTooltip:
                  widget.embedded ? l10n('Kapat', 'Close') : l10n('Geri', 'Back'),
              actions: [
                IconButton(
                  onPressed: _isLoading ? null : _loadData,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: l10n('Yenile', 'Refresh'),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: () => _showFormDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n('Kategori Ekle', 'Add Category')),
                ),
              ],
            ),
            Material(
              color: scheme.surface,
              child: TabBar(
                tabs: [
                  Tab(icon: const Icon(Icons.list_alt_rounded), text: l10n('Liste', 'List')),
                  Tab(icon: const Icon(Icons.insights_rounded), text: l10n('Analiz', 'Analysis')),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _CategoryListTab(
                    isLoading: _isLoading,
                    categories: filtered,
                    hasCategories: _categories.isNotEmpty,
                    searchController: _searchController,
                    onSearch: (value) => setState(() => _query = value),
                    onAdd: () => _showFormDialog(),
                    onOpen: (name) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryBooksScreen(
                            categoryName: name,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) _loadData();
                      });
                    },
                    onEdit: (item) => _showFormDialog(
                      id: item['id'] as int,
                      currentName: item['name'] as String,
                    ),
                    onDelete: (item) => _confirmDelete(
                      item['id'] as int,
                      item['name'] as String,
                      item['book_count'] as int,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: CategoryAnalysisWidget(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryListTab extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> categories;
  final bool hasCategories;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onAdd;
  final ValueChanged<String> onOpen;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

  const _CategoryListTab({
    required this.isLoading,
    required this.categories,
    required this.hasCategories,
    required this.searchController,
    required this.onSearch,
    required this.onAdd,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: SectionSearchField(
            controller: searchController,
            hintText: l10n('Kategori ara...', 'Search categories...'),
            onChanged: onSearch,
          ),
        ),
        Expanded(
          child: !hasCategories
              ? SectionEmptyState(
                  icon: Icons.category_outlined,
                  title: l10n('Henüz kategori yok', 'No categories yet'),
                  description: l10n(
                    'Kitap koleksiyonunu düzenlemek için ilk kategorinizi oluşturun.',
                    'Create your first category to organize the book collection.',
                  ),
                  actionLabel: l10n('Kategori Ekle', 'Add Category'),
                  onAction: onAdd,
                )
              : categories.isEmpty
                  ? SectionEmptyState(
                      icon: Icons.search_off_rounded,
                      title: l10n('Kategori bulunamadı', 'No categories found'),
                      description: l10n(
                        'Arama ifadenizi değiştirerek tekrar deneyin.',
                        'Try changing your search query.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = categories[index];
                        final count = item['book_count'] as int;
                        final name = item['name'] as String;
                        final initial = name.trim().isEmpty
                            ? '#'
                            : name.trim().substring(0, 1).toUpperCase();

                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer.withValues(
                                  alpha: 0.55,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              l10n(
                                count == 1 ? '1 kitap' : '$count kitap',
                                count == 1 ? '1 book' : '$count books',
                              ),
                            ),
                            onTap: () => onOpen(name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => onEdit(item),
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: l10n('Düzenle', 'Edit'),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: l10n('Diğer işlemler', 'More actions'),
                                  onSelected: (value) {
                                    if (value == 'delete') onDelete(item);
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete_outline_rounded),
                                          const SizedBox(width: 10),
                                          Text(l10n('Sil', 'Delete')),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

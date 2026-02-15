import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
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
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final data = await service.getCategoriesWithStats();
    if (mounted) {
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _showFormDialog({int? id, String? currentName}) async {
    final controller = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Kategori Ekle' : 'Kategori Duzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Kategori Adi'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              try {
                if (id == null) {
                  await service.addCategory(name);
                } else {
                  await service.updateCategory(id, name);
                }
                if (mounted) Navigator.pop(context);
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int id, String name) async {
    try {
      await service.deleteCategory(id, name);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori silindi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Silinemedi'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: widget.embedded
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                )
              : null,
          title: widget.embedded ? null : const Text('Kategori Yonetimi'),
          bottom: widget.embedded
              ? null
              : const TabBar(
                  tabs: [
                    Tab(text: 'Liste'),
                    Tab(text: 'Analiz'),
                  ],
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showFormDialog(),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            if (widget.embedded)
              const TabBar(
                tabs: [
                  Tab(text: 'Liste'),
                  Tab(text: 'Analiz'),
                ],
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _categories.isEmpty
                            ? const Center(child: Text('Henuz kategori eklenmemis.'))
                            : ListView.separated(
                                itemCount: _categories.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = _categories[index];
                                  final count = item['book_count'] as int;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(item['name'].substring(0, 1).toUpperCase()),
                                    ),
                                    title: Text(item['name']),
                                    subtitle: Text('$count kitap kayitli'),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryBooksScreen(
                                            categoryName: item['name'],
                                          ),
                                        ),
                                      ).then((_) => _loadData());
                                    },
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showFormDialog(
                                            id: item['id'],
                                            currentName: item['name'],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _delete(item['id'], item['name']),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        const SingleChildScrollView(child: CategoryAnalysisWidget()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


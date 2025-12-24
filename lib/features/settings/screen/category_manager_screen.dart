import 'package:flutter/material.dart';
import 'package:libris/features/home/screens/widgets/category_analysis_widget.dart';
import 'package:libris/features/settings/screen/category_books_screen.dart';
import 'package:libris/features/settings/services/category_service.dart';

class CategoryManagerScreen extends StatefulWidget {
  final CategoryService service;

  const CategoryManagerScreen({super.key, required this.service});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await widget.service.init(); // Tablo yoksa oluşturur ve migrate eder
    final data = await widget.service.getCategoriesWithStats();
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
        title: Text(id == null ? 'Kategori Ekle' : 'Kategori Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Kategori Adı'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              try {
                if (id == null) {
                  await widget.service.addCategory(name);
                } else {
                  await widget.service.updateCategory(id, name);
                }
                if (mounted) Navigator.pop(context);
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
      await widget.service.deleteCategory(id, name);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kategori silindi.')));
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
          title: const Text('Kategori Yönetimi'),
          bottom: const TabBar(
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // TAB 1: LİSTE
                  _categories.isEmpty
                      ? const Center(child: Text('Henüz kategori eklenmemiş.'))
                      : ListView.separated(
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _categories[index];
                            final count = item['book_count'] as int;
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  item['name'].substring(0, 1).toUpperCase(),
                                ),
                              ),
                              title: Text(item['name']),
                              subtitle: Text('$count kitap kayıtlı'),
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
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _showFormDialog(
                                      id: item['id'],
                                      currentName: item['name'],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _delete(item['id'], item['name']),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                  // TAB 2: ANALİZ
                  SingleChildScrollView(
                    child: CategoryAnalysisWidget(categoryStats: _categories),
                  ),
                ],
              ),
      ),
    );
  }
}

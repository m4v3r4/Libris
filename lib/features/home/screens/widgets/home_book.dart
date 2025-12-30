import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';

class HomeBook extends StatefulWidget {
  const HomeBook({super.key});

  @override
  State<HomeBook> createState() => _HomeBookState();
}

class _HomeBookState extends State<HomeBook>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Book> _topBooks = [];
  List<Book> _latestBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // BookService'de bu metodların olduğunu varsayıyoruz
      final top = await _databaseHelper.getTopBooks();
      final latest = await _databaseHelper.getLatestBooks();

      if (mounted) {
        setState(() {
          _topBooks = top;
          _latestBooks = latest;
        });
      }
    } catch (e) {
      debugPrint('Kitap verileri yüklenirken hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Kitap İstatistikleri',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'En Çok Okunanlar'),
              Tab(text: 'Son Eklenenler'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookList(
                        _topBooks,
                        Icons.auto_stories,
                        Colors.purple,
                      ),
                      _buildBookList(
                        _latestBooks,
                        Icons.new_releases,
                        Colors.teal,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(List<Book> books, IconData icon, Color iconColor) {
    if (books.isEmpty) {
      return const Center(child: Text('Kayıt bulunamadı.'));
    }
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = books[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            book.title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(book.author),
          trailing: const Icon(
            Icons.chevron_right,
            size: 16,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}

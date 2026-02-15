import 'package:flutter/material.dart';
import 'package:libris/common/providers/database_provider.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:provider/provider.dart';

class HomeBook extends StatefulWidget {
  const HomeBook({super.key});

  @override
  State<HomeBook> createState() => _HomeBookState();
}

class _HomeBookState extends State<HomeBook> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DatabaseProvider? _provider;
  late Future<List<List<Book>>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<DatabaseProvider>();

    if (!identical(_provider, nextProvider)) {
      _provider?.removeListener(_onDatabaseChanged);
      _provider = nextProvider;
      _provider!.addListener(_onDatabaseChanged);
      _reload();
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onDatabaseChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onDatabaseChanged() {
    _reload();
  }

  void _reload() {
    final provider = _provider;
    if (provider == null) return;

    setState(() {
      _statsFuture = Future.wait([
        provider.db.getTopBooks(),
        provider.db.getLatestBooks(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Kitap Istatistikleri',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'En Cok Okunanlar'),
              Tab(text: 'Son Eklenenler'),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<List<Book>>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookList(data[0], Icons.auto_stories, const Color(0xFFE95420)),
                    _buildBookList(data[1], Icons.new_releases, const Color(0xFF2C001E)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(List<Book> books, IconData icon, Color iconColor) {
    if (books.isEmpty) {
      return const Center(child: Text('Kayit bulunamadi.'));
    }

    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = books[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}


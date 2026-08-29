import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/providers/database_provider.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:libris/features/home/screens/widgets/dashboard_card.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return DashboardCard(
      title: l10n('Kitaplar', 'Books'),
      subtitle: l10n('Okuma ve katalog hareketleri', 'Reading and catalog activity'),
      icon: Icons.menu_book_rounded,
      trailing: IconButton(
        onPressed: _reload,
        icon: const Icon(Icons.refresh_rounded),
        tooltip: l10n('Yenile', 'Refresh'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n('En Çok Okunanlar', 'Most Read')),
              Tab(text: l10n('Son Eklenenler', 'Recently Added')),
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
                    _buildBookList(
                      data[0],
                      Icons.auto_stories_rounded,
                      scheme.primary,
                    ),
                    _buildBookList(
                      data[1],
                      Icons.new_releases_rounded,
                      scheme.secondary,
                    ),
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
      return DashboardEmptyState(
        icon: Icons.menu_book_outlined,
        title: l10n('Henüz kitap verisi yok', 'No book data yet'),
        description: l10n(
          'Kitaplar eklendikçe istatistikler burada oluşacak.',
          'Statistics will appear here as books are added.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

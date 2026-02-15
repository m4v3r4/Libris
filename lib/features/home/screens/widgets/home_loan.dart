import 'package:flutter/material.dart';
import 'package:libris/common/providers/database_provider.dart';
import 'package:provider/provider.dart';

class HomeLoan extends StatefulWidget {
  const HomeLoan({super.key});

  @override
  State<HomeLoan> createState() => _HomeLoanState();
}

class _HomeLoanState extends State<HomeLoan> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DatabaseProvider? _provider;
  late Future<List<List<Map<String, dynamic>>>> _statsFuture;

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
        provider.db.getOverdueLoans(),
        provider.db.getRecentLoans(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Emanet Durumu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Yenile',
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Gecikenler'),
              Tab(text: 'Son Islemler'),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<List<Map<String, dynamic>>>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(data[0], isOverdue: true),
                    _buildList(data[1]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {bool isOverdue = false}) {
    if (items.isEmpty) {
      return const Center(child: Text('Kayit bulunamadi.'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final bookTitle = item['bookTitle']?.toString() ?? 'Kitap silinmis';
        final memberName = item['memberName']?.toString() ?? 'Uye silinmis';

        IconData icon;
        Color color;
        String subtitle;

        if (isOverdue) {
          final date = item['dueDate'];
          final dateStr = date != null && date.toString().length > 10
              ? date.toString().substring(0, 10)
              : (date?.toString() ?? '-');
          icon = Icons.warning_amber_rounded;
          color = Colors.red;
          subtitle = '$memberName\nSon gun: $dateStr';
        } else {
          final isReturned = item['returnedAt'] != null;
          final date = item['updatedAt'];
          final dateStr = date != null && date.toString().length > 16
              ? date.toString().substring(0, 16).replaceFirst('T', ' ')
              : (date?.toString() ?? '');

          if (isReturned) {
            icon = Icons.check_circle_outline;
            color = Colors.green;
            subtitle = 'Teslim alindi: $memberName\n$dateStr';
          } else {
            icon = Icons.arrow_circle_right_outlined;
            color = Colors.blue;
            subtitle = 'Teslim edildi: $memberName\n$dateStr';
          }
        }

        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            bookTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(subtitle),
          isThreeLine: true,
          dense: true,
        );
      },
    );
  }
}


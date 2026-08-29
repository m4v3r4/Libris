import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/providers/database_provider.dart';
import 'package:libris/features/home/screens/widgets/dashboard_card.dart';
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
    return DashboardCard(
      title: l10n('Emanetler', 'Loans'),
      subtitle: l10n('Gecikenler ve son işlemler', 'Overdue and recent activity'),
      icon: Icons.swap_horiz_rounded,
      trailing: IconButton(
        onPressed: _reload,
        icon: const Icon(Icons.refresh_rounded),
        tooltip: l10n('Yenile', 'Refresh'),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n('Gecikenler', 'Overdue')),
              Tab(text: l10n('Son İşlemler', 'Recent Activity')),
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
      return DashboardEmptyState(
        icon: isOverdue ? Icons.event_available_rounded : Icons.history_rounded,
        title: isOverdue
            ? l10n('Geciken emanet yok', 'No overdue loans')
            : l10n('Henüz emanet hareketi yok', 'No loan activity yet'),
        description: isOverdue
            ? l10n(
                'Süresi geçen bir emanet bulunmuyor.',
                'There are no loans past their due date.',
              )
            : l10n(
                'Emanet işlemleri yapıldıkça burada görünecek.',
                'Loan activity will appear here as transactions are created.',
              ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final bookTitle = item['bookTitle']?.toString() ??
            l10n('Kitap silinmiş', 'Deleted book');
        final memberName = item['memberName']?.toString() ??
            l10n('Üye silinmiş', 'Deleted member');

        IconData icon;
        Color color;
        String subtitle;

        if (isOverdue) {
          final date = item['dueDate'];
          final dateStr = date != null && date.toString().length > 10
              ? date.toString().substring(0, 10)
              : (date?.toString() ?? '-');
          icon = Icons.warning_amber_rounded;
          color = scheme.error;
          subtitle = '$memberName\n${l10n('Son gün', 'Due')}: $dateStr';
        } else {
          final isReturned = item['returnedAt'] != null;
          final date = item['updatedAt'];
          final dateStr = date != null && date.toString().length > 16
              ? date.toString().substring(0, 16).replaceFirst('T', ' ')
              : (date?.toString() ?? '');

          if (isReturned) {
            icon = Icons.check_circle_outline_rounded;
            color = Colors.green;
            subtitle = '${l10n('Teslim alındı', 'Returned')}: $memberName\n$dateStr';
          } else {
            icon = Icons.arrow_circle_right_outlined;
            color = scheme.primary;
            subtitle = '${l10n('Teslim edildi', 'Loaned to')}: $memberName\n$dateStr';
          }
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 19),
          ),
          title: Text(
            bookTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          isThreeLine: true,
          dense: true,
        );
      },
    );
  }
}

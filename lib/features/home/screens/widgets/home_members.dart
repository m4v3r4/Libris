import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/models/member.dart';
import 'package:libris/common/providers/database_provider.dart';
import 'package:libris/features/home/screens/widgets/dashboard_card.dart';
import 'package:provider/provider.dart';

class HomeMembers extends StatefulWidget {
  const HomeMembers({super.key});

  @override
  State<HomeMembers> createState() => _HomeMembersState();
}

class _HomeMembersState extends State<HomeMembers>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DatabaseProvider? _provider;
  late Future<List<List<Member>>> _statsFuture;

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
        provider.db.getTopMembers(),
        provider.db.getLatestMembers(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DashboardCard(
      title: l10n('Üyeler', 'Members'),
      subtitle: l10n(
        'Okuyucu hareketleri ve yeni kayıtlar',
        'Reader activity and new registrations',
      ),
      icon: Icons.groups_2_rounded,
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
              Tab(text: l10n('En Çok Okuyanlar', 'Top Readers')),
              Tab(text: l10n('Son Üyeler', 'Recent Members')),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<List<Member>>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMemberList(
                      data[0],
                      Icons.workspace_premium_rounded,
                      scheme.primary,
                    ),
                    _buildMemberList(
                      data[1],
                      Icons.person_add_alt_1_rounded,
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

  Widget _buildMemberList(
    List<Member> members,
    IconData icon,
    Color iconColor,
  ) {
    if (members.isEmpty) {
      return DashboardEmptyState(
        icon: Icons.group_outlined,
        title: l10n('Henüz üye verisi yok', 'No member data yet'),
        description: l10n(
          'Üyeler eklendikçe hareketler burada görünecek.',
          'Activity will appear here as members are added.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: members.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = members[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(
            member.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            member.email ?? member.phone ?? '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

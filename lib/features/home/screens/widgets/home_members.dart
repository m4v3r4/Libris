import 'package:flutter/material.dart';
import 'package:libris/common/models/Member.dart';
import 'package:libris/common/providers/database_provider.dart';
import 'package:provider/provider.dart';

class HomeMembers extends StatefulWidget {
  const HomeMembers({super.key});

  @override
  State<HomeMembers> createState() => _HomeMembersState();
}

class _HomeMembersState extends State<HomeMembers> with SingleTickerProviderStateMixin {
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Uye Istatistikleri',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'En Cok Okuyanlar'),
              Tab(text: 'Son Uyeler'),
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
                    _buildMemberList(data[0], Icons.star, const Color(0xFFE95420)),
                    _buildMemberList(data[1], Icons.person_add, const Color(0xFF2C001E)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(List<Member> members, IconData icon, Color iconColor) {
    if (members.isEmpty) {
      return const Center(child: Text('Kayit bulunamadi.'));
    }

    return ListView.separated(
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


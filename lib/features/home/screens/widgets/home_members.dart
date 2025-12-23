import 'package:flutter/material.dart';
import 'package:libris/features/members/models/member.dart';
import 'package:libris/features/members/services/members_service.dart';

class HomeMembers extends StatefulWidget {
  const HomeMembers({super.key});

  @override
  State<HomeMembers> createState() => _HomeMembersState();
}

class _HomeMembersState extends State<HomeMembers>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MembersService _membersService = MembersService();

  List<Member> _topMembers = [];
  List<Member> _latestMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final top = await _membersService.getTopMembers();
    final latest = await _membersService.getLatestMembers();

    if (mounted) {
      setState(() {
        _topMembers = top;
        _latestMembers = latest;
        _isLoading = false;
      });
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
              'Üye İstatistikleri',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'En Çok Okuyanlar'),
              Tab(text: 'Son Üyeler'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMemberList(_topMembers, Icons.star, Colors.orange),
                      _buildMemberList(
                        _latestMembers,
                        Icons.person_add,
                        Colors.blue,
                      ),
                    ],
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
      return const Center(child: Text('Kayıt bulunamadı.'));
    }
    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = members[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            member.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(member.email ?? member.phone ?? '-'),
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

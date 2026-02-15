import 'package:flutter/material.dart';
import 'package:libris/common/models/Member.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/members/screens/member_detail_screen.dart';
import 'package:libris/features/members/screens/member_form_screen.dart';

class MembersListScreen extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onClose;

  const MembersListScreen({super.key, this.embedded = false, this.onClose});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final DatabaseHelper _memberService = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final members = await _memberService.getMembers();
    setState(() {
      _members = members;
      _filteredMembers = members;
      _isLoading = false;
    });
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredMembers = _members.where((member) {
        return member.name.toLowerCase().contains(query) ||
            (member.email?.toLowerCase().contains(query) ?? false) ||
            (member.phone?.contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _openForm({Member? member}) async {
    if (member == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MemberFormScreen()),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MemberDetailScreen(member: member)),
      );
    }
    _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.embedded
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
              )
            : null,
        title: widget.embedded ? null : const Text('Uyeler'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Uye ara (isim, e-posta, telefon)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                ? const Center(child: Text('Uye bulunamadi'))
                : ListView.builder(
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = _filteredMembers[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(member.name),
                        subtitle: Text(
                          member.email ?? member.phone ?? 'Iletisim bilgisi yok',
                        ),
                        onTap: () => _openForm(member: member),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}


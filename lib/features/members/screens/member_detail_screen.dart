import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/members/models/member.dart';
import 'package:libris/features/members/screens/member_form_screen.dart';

class MemberDetailScreen extends StatefulWidget {
  final Member member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final DatabaseHelper _memberService = DatabaseHelper.instance;
  late Member _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  Future<void> _editMember() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemberFormScreen(member: _member)),
    );

    if (result == true) {
      final updated = await _memberService.getMemberById(_member.id!);
      if (updated != null) {
        setState(() => _member = updated);
      }
    }
  }

  Future<void> _deleteMember() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Üyeyi Sil'),
        content: const Text('Bu üyeyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _memberService.deleteMember(_member.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Widget _infoTile(String label, String? value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value ?? '-'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Üye Detayı'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editMember),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteMember),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _member.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 24),
          _infoTile('E-posta', _member.email, Icons.email),
          _infoTile('Telefon', _member.phone, Icons.phone),
          _infoTile('Adres', _member.address, Icons.location_on),
          _infoTile(
            'Kayıt Tarihi',
            _member.createdAt.toLocal().toString(),
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/models/member.dart';
import 'package:libris/common/providers/database_provider.dart';
import 'package:libris/features/members/screens/member_form_screen.dart';
import 'package:provider/provider.dart';

class MemberDetailScreen extends StatefulWidget {
  final Member member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late Member _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  Future<void> _editMember() async {
    final provider = context.read<DatabaseProvider>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemberFormScreen(member: _member)),
    );

    if (!mounted || result != true) return;

    final updated = await provider.db.getMemberById(_member.id!);
    if (!mounted || updated == null) return;
    setState(() => _member = updated);
  }

  Future<void> _deleteMember() async {
    final provider = context.read<DatabaseProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n('Üyeyi Sil', 'Delete Member')),
        content: Text(
          l10n(
            'Bu üyeyi silmek istediğinize emin misiniz?',
            'Are you sure you want to delete this member?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n('İptal', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n('Sil', 'Delete')),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    await provider.deleteMember(_member.id!);
    if (!mounted) return;
    Navigator.pop(context, true);
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
        title: Text(l10n('Üye Detayı', 'Member Details')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n('Düzenle', 'Edit'),
            onPressed: _editMember,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: l10n('Sil', 'Delete'),
            onPressed: _deleteMember,
          ),
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
          _infoTile(l10n('E-posta', 'Email'), _member.email, Icons.email),
          _infoTile(l10n('Telefon', 'Phone'), _member.phone, Icons.phone),
          _infoTile(l10n('Adres', 'Address'), _member.address, Icons.location_on),
          _infoTile(
            l10n('Kayıt Tarihi', 'Registration Date'),
            _member.createdAt.toLocal().toString(),
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }
}

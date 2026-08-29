import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/models/member.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/common/widgets/section_toolbar.dart';
import 'package:libris/features/members/screens/member_detail_screen.dart';
import 'package:libris/features/members/screens/member_form_screen.dart';

enum MemberSortType { nameAsc, newest }

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
  bool _isLoading = true;
  MemberSortType _sortType = MemberSortType.nameAsc;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final members = await _memberService.getMembers();
    if (!mounted) return;
    setState(() {
      _members = members;
      _isLoading = false;
    });
  }

  List<Member> get _filteredMembers {
    final query = _searchController.text.trim().toLowerCase();
    final result = _members.where((member) {
      if (query.isEmpty) return true;
      return member.name.toLowerCase().contains(query) ||
          (member.email?.toLowerCase().contains(query) ?? false) ||
          (member.phone?.toLowerCase().contains(query) ?? false) ||
          (member.address?.toLowerCase().contains(query) ?? false);
    }).toList();

    switch (_sortType) {
      case MemberSortType.nameAsc:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case MemberSortType.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return result;
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
    if (!mounted) return;
    await _loadMembers();
  }

  void _close() {
    if (widget.embedded) {
      widget.onClose?.call();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMembers;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          SectionToolbar(
            title: l10n('Üyeler', 'Members'),
            subtitle: l10n(
              'Üye kayıtlarını ve iletişim bilgilerini yönetin.',
              'Manage member records and contact information.',
            ),
            icon: Icons.groups_2_rounded,
            count: filtered.length,
            onClose: _close,
            leadingIcon:
                widget.embedded ? Icons.close_rounded : Icons.arrow_back_rounded,
            leadingTooltip:
                widget.embedded ? l10n('Kapat', 'Close') : l10n('Geri', 'Back'),
            actions: [
              PopupMenuButton<MemberSortType>(
                tooltip: l10n('Sırala', 'Sort'),
                initialValue: _sortType,
                onSelected: (value) => setState(() => _sortType = value),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: MemberSortType.nameAsc,
                    child: Text(l10n('İsme göre A → Z', 'Name A → Z')),
                  ),
                  PopupMenuItem(
                    value: MemberSortType.newest,
                    child: Text(l10n('En yeni üyeler', 'Newest members')),
                  ),
                ],
                icon: const Icon(Icons.sort_by_alpha_rounded),
              ),
              IconButton(
                onPressed: _loadMembers,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n('Yenile', 'Refresh'),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: scheme.surface.withValues(alpha: 0.45),
            child: SectionSearchField(
              controller: _searchController,
              hintText: l10n(
                'İsim, e-posta, telefon veya adres ara...',
                'Search name, email, phone, or address...',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? SectionEmptyState(
                        icon: _members.isEmpty
                            ? Icons.person_add_alt_1_rounded
                            : Icons.search_off_rounded,
                        title: _members.isEmpty
                            ? l10n('Henüz üye yok', 'No members yet')
                            : l10n(
                                'Aramanızla eşleşen üye bulunamadı',
                                'No members match your search',
                              ),
                        description: _members.isEmpty
                            ? l10n(
                                'İlk üye kaydını oluşturarak başlayın.',
                                'Start by creating your first member record.',
                              )
                            : l10n(
                                'Arama ifadesini değiştirin veya temizleyin.',
                                'Change or clear your search query.',
                              ),
                        actionLabel:
                            _members.isEmpty ? l10n('Üye Ekle', 'Add Member') : null,
                        onAction: _members.isEmpty ? () => _openForm() : null,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final member = filtered[index];
                          final trimmedName = member.name.trim();
                          final initial = trimmedName.isEmpty
                              ? '?'
                              : trimmedName[0].toUpperCase();

                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: scheme.primaryContainer,
                                foregroundColor: scheme.onPrimaryContainer,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(
                                member.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 3,
                                  children: [
                                    if ((member.email ?? '').isNotEmpty)
                                      _MemberMeta(
                                        icon: Icons.alternate_email_rounded,
                                        text: member.email!,
                                      ),
                                    if ((member.phone ?? '').isNotEmpty)
                                      _MemberMeta(
                                        icon: Icons.phone_outlined,
                                        text: member.phone!,
                                      ),
                                    if ((member.email ?? '').isEmpty &&
                                        (member.phone ?? '').isEmpty)
                                      Text(l10n('İletişim bilgisi yok', 'No contact information')),
                                  ],
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: scheme.onSurfaceVariant,
                              ),
                              onTap: () => _openForm(member: member),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(l10n('Üye Ekle', 'Add Member')),
      ),
    );
  }
}

class _MemberMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MemberMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

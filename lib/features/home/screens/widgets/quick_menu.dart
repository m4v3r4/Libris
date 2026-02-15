import 'package:flutter/material.dart';
import 'package:libris/features/books/screen/book_form_screen.dart';
import 'package:libris/features/loans/screen/loan_form_screen.dart';
import 'package:libris/features/loans/screen/loan_list_screen.dart';
import 'package:libris/features/members/screens/member_form_screen.dart';
import 'package:libris/features/settings/screen/category_manager_screen.dart';
import 'package:libris/features/settings/screen/settings_screen.dart';

class QuickMenu extends StatefulWidget {
  const QuickMenu({super.key});

  @override
  State<QuickMenu> createState() => _QuickMenuState();
}

class _QuickMenuState extends State<QuickMenu> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recent = [];

  late final List<_QuickAction> _actions = [
    _QuickAction(
      id: 'book_add',
      title: 'Kitap Ekle',
      subtitle: 'Yeni kitap kaydi olustur',
      icon: Icons.add_box_outlined,
      builder: () => BookFormScreen(),
    ),
    _QuickAction(
      id: 'member_add',
      title: 'Uye Ekle',
      subtitle: 'Yeni uye kaydi olustur',
      icon: Icons.person_add_alt_1,
      builder: () => const MemberFormScreen(),
    ),
    _QuickAction(
      id: 'loan_add',
      title: 'Emanet Ver',
      subtitle: 'Kitap odunc islemi baslat',
      icon: Icons.swap_horizontal_circle_outlined,
      builder: () => LoanFormScreen(),
    ),
    _QuickAction(
      id: 'loan_list',
      title: 'Emanet Listesi',
      subtitle: 'Tum emanetleri goruntule',
      icon: Icons.list_alt_rounded,
      builder: () => const LoanListScreen(),
    ),
    _QuickAction(
      id: 'category',
      title: 'Kategoriler',
      subtitle: 'Kategori yonetimini ac',
      icon: Icons.category_outlined,
      builder: () => CategoryManagerScreen(),
    ),
    _QuickAction(
      id: 'settings',
      title: 'Ayarlar',
      subtitle: 'Tema ve uygulama ayarlari',
      icon: Icons.tune_rounded,
      builder: () => const SettingsScreen(),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_QuickAction> get _filteredActions {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _actions;

    return _actions
        .where(
          (a) =>
              a.title.toLowerCase().contains(query) ||
              a.subtitle.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final actions = _filteredActions;
    final recentActions = _actions.where((a) => _recent.contains(a.id)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hizli Menu', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Islem ara...',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
            ),
            if (recentActions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: recentActions
                    .map(
                      (a) => ActionChip(
                        label: Text(a.title),
                        avatar: Icon(a.icon, size: 16),
                        onPressed: () => _openAction(a),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 420 ? 2 : 1;

                  return GridView.builder(
                    itemCount: actions.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.4,
                    ),
                    itemBuilder: (context, index) {
                      final action = actions[index];

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openAction(action),
                        child: Ink(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.45),
                          ),
                          child: Row(
                            children: [
                              Icon(action.icon),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      action.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      action.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAction(_QuickAction action) {
    setState(() {
      _recent.remove(action.id);
      _recent.insert(0, action.id);
      if (_recent.length > 3) {
        _recent.removeLast();
      }
    });

    Navigator.push(context, MaterialPageRoute(builder: (_) => action.builder()));
  }
}

class _QuickAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;

  const _QuickAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}


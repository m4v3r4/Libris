import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/features/books/screen/book_form_screen.dart';
import 'package:libris/features/books/screen/book_list_screen.dart';
import 'package:libris/features/home/screens/widgets/dashboard_card.dart';
import 'package:libris/features/loans/screen/loan_form_screen.dart';
import 'package:libris/features/loans/screen/loan_list_screen.dart';
import 'package:libris/features/members/screens/member_form_screen.dart';
import 'package:libris/features/members/screens/members_list_screen.dart';
import 'package:libris/features/settings/screen/category_manager_screen.dart';
import 'package:libris/features/settings/screen/settings_screen.dart';

class QuickMenu extends StatelessWidget {
  const QuickMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actions = <_QuickAction>[
      _QuickAction(
        title: l10n('Emanet Ver', 'Create Loan'),
        subtitle: l10n('Ödünç işlemi başlat', 'Start a lending transaction'),
        icon: Icons.swap_horizontal_circle_outlined,
        builder: () => const LoanFormScreen(),
        primary: true,
      ),
      _QuickAction(
        title: l10n('Kitap Ekle', 'Add Book'),
        subtitle: l10n('Yeni kayıt oluştur', 'Create a new record'),
        icon: Icons.add_box_outlined,
        builder: () => const BookFormScreen(),
        primary: true,
      ),
      _QuickAction(
        title: l10n('Üye Ekle', 'Add Member'),
        subtitle: l10n('Yeni üye oluştur', 'Create a new member'),
        icon: Icons.person_add_alt_1_rounded,
        builder: () => const MemberFormScreen(),
        primary: true,
      ),
      _QuickAction(
        title: l10n('Emanetler', 'Loans'),
        subtitle: l10n('Tüm hareketleri gör', 'View all loan activity'),
        icon: Icons.fact_check_outlined,
        builder: () => const LoanListScreen(),
      ),
      _QuickAction(
        title: l10n('Kitaplar', 'Books'),
        subtitle: l10n('Kataloğu görüntüle', 'Browse the catalog'),
        icon: Icons.menu_book_rounded,
        builder: () => const BookListScreen(),
      ),
      _QuickAction(
        title: l10n('Üyeler', 'Members'),
        subtitle: l10n('Üye listesini aç', 'Open the member list'),
        icon: Icons.groups_2_rounded,
        builder: () => const MembersListScreen(),
      ),
      _QuickAction(
        title: l10n('Kategoriler', 'Categories'),
        subtitle: l10n('Kategorileri yönet', 'Manage categories'),
        icon: Icons.category_outlined,
        builder: () => const CategoryManagerScreen(),
      ),
      _QuickAction(
        title: l10n('Ayarlar', 'Settings'),
        subtitle: l10n('Uygulamayı yapılandır', 'Configure the application'),
        icon: Icons.tune_rounded,
        builder: () => const SettingsScreen(),
      ),
    ];

    return DashboardCard(
      title: l10n('Hızlı İşlemler', 'Quick Actions'),
      subtitle: l10n('En sık kullanılan işlemler', 'Frequently used actions'),
      icon: Icons.bolt_rounded,
      bodyPadding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 8.0;
          final columns = constraints.maxWidth >= 700
              ? 4
              : constraints.maxWidth >= 500
                  ? 3
                  : constraints.maxWidth >= 300
                      ? 2
                      : 1;
          final rows = (actions.length / columns).ceil();
          final tileWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          final tileHeight =
              (constraints.maxHeight - spacing * (rows - 1)) / rows;
          final aspectRatio = tileHeight <= 0 ? 2.0 : tileWidth / tileHeight;
          final dense = tileHeight < 76 || tileWidth < 170;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _QuickActionTile(
                action: action,
                dense: dense,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => action.builder()),
                ),
                scheme: scheme,
              );
            },
          );
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  final bool dense;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _QuickActionTile({
    required this.action,
    required this.dense,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final background = action.primary
        ? scheme.primaryContainer.withValues(alpha: 0.42)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.42);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 9 : 11,
          vertical: dense ? 7 : 9,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: background,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: dense ? 32 : 36,
              height: dense ? 32 : 36,
              decoration: BoxDecoration(
                color: action.primary
                    ? scheme.primaryContainer
                    : scheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                action.icon,
                size: dense ? 18 : 20,
                color: action.primary ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (!dense) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (!dense) ...[
              const SizedBox(width: 5),
              Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;
  final bool primary;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
    this.primary = false,
  });
}

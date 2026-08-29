import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';

enum LeftbarDestination {
  books,
  members,
  loans,
  categories,
  settings,
}

class Leftbar extends StatelessWidget {
  final ValueChanged<LeftbarDestination> onSelect;
  final LeftbarDestination? selected;

  const Leftbar({super.key, required this.onSelect, this.selected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/branding/libris-icon-128.png',
                    width: 46,
                    height: 46,
                    filterQuality: FilterQuality.high,
                    semanticLabel: l10n('Libris logosu', 'Libris logo'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Libris',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n('Kütüphane yönetimi', 'Library management'),
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                children: [
                  _LeftBarItem(
                    icon: Icons.menu_book_rounded,
                    title: l10n('Kitaplar', 'Books'),
                    selected: selected == LeftbarDestination.books,
                    onTap: () => onSelect(LeftbarDestination.books),
                  ),
                  _LeftBarItem(
                    icon: Icons.groups_2_rounded,
                    title: l10n('Üyeler', 'Members'),
                    selected: selected == LeftbarDestination.members,
                    onTap: () => onSelect(LeftbarDestination.members),
                  ),
                  _LeftBarItem(
                    icon: Icons.swap_horiz_rounded,
                    title: l10n('Emanetler', 'Loans'),
                    selected: selected == LeftbarDestination.loans,
                    onTap: () => onSelect(LeftbarDestination.loans),
                  ),
                  _LeftBarItem(
                    icon: Icons.category_rounded,
                    title: l10n('Kategoriler', 'Categories'),
                    selected: selected == LeftbarDestination.categories,
                    onTap: () => onSelect(LeftbarDestination.categories),
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: scheme.outlineVariant),
                  const SizedBox(height: 8),
                  _LeftBarItem(
                    icon: Icons.settings_rounded,
                    title: l10n('Ayarlar', 'Settings'),
                    selected: selected == LeftbarDestination.settings,
                    onTap: () => onSelect(LeftbarDestination.settings),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n('Çevrimdışı öncelikli', 'Offline-first'),
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    'v1.2.0',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftBarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LeftBarItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        minLeadingWidth: 24,
        leading: Icon(icon, size: 20),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? Icon(Icons.circle, size: 7, color: scheme.primary)
            : null,
        selected: selected,
        selectedColor: scheme.primary,
        selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

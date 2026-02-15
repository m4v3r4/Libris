import 'package:flutter/material.dart';

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

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              color: scheme.primaryContainer.withValues(alpha: 0.55),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Libris', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('Kutuphane Yonetimi', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _LeftBarItem(
                  icon: Icons.menu_book_rounded,
                  title: 'Kitaplar',
                  selected: selected == LeftbarDestination.books,
                  onTap: () => onSelect(LeftbarDestination.books),
                ),
                _LeftBarItem(
                  icon: Icons.groups_2_rounded,
                  title: 'Uyeler',
                  selected: selected == LeftbarDestination.members,
                  onTap: () => onSelect(LeftbarDestination.members),
                ),
                _LeftBarItem(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Emanetler',
                  selected: selected == LeftbarDestination.loans,
                  onTap: () => onSelect(LeftbarDestination.loans),
                ),
                _LeftBarItem(
                  icon: Icons.category_rounded,
                  title: 'Kategoriler',
                  selected: selected == LeftbarDestination.categories,
                  onTap: () => onSelect(LeftbarDestination.categories),
                ),
                _LeftBarItem(
                  icon: Icons.settings_rounded,
                  title: 'Ayarlar',
                  selected: selected == LeftbarDestination.settings,
                  onTap: () => onSelect(LeftbarDestination.settings),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text('v1.0.1', style: Theme.of(context).textTheme.labelSmall),
          ),
        ],
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
    final activeColor = scheme.primary;

    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: selected ? activeColor : null),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? activeColor : null,
        ),
      ),
      trailing: selected
          ? Icon(Icons.radio_button_checked_rounded, size: 14, color: activeColor)
          : const Icon(Icons.chevron_right_rounded, size: 18),
      selected: selected,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(Icons.book),
          label: l10n('Kitaplar', 'Books'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people),
          label: l10n('Üyeler', 'Members'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: l10n('Ayarlar', 'Settings'),
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      onTap: onItemTapped,
    );
  }
}

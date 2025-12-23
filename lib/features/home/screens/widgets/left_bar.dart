import 'package:flutter/material.dart';
import 'package:libris/features/books/screen/book_list_screen.dart';
import 'package:libris/features/loans/screen/loan_list_screen.dart';
import 'package:libris/features/members/screens/members_list_screen.dart';
import 'package:libris/features/settings/screen/settings_screen.dart';

class Leftbar extends StatefulWidget {
  const Leftbar({super.key});

  @override
  State<Leftbar> createState() => _LeftbarState();
}

class _LeftbarState extends State<Leftbar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1),

        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(50),
          bottomRight: Radius.circular(0),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        children: [
          LeftBarItem(
            icon: Icons.book,
            title: 'Kitaplar',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookListScreen()),
              );
            },
          ),
          LeftBarItem(
            icon: Icons.people,
            title: 'Üyeler',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MembersListScreen(),
                ),
              );
            },
          ),
          LeftBarItem(
            icon: Icons.transform,
            title: 'Emanetler',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoanListScreen()),
              );
            },
          ),
          LeftBarItem(
            icon: Icons.data_saver_off,
            title: 'Veri Tabanı',
            onTap: () {
              // Ayarlar sayfasına yönlendirme kodu buraya gelecek
            },
          ),
          LeftBarItem(
            icon: Icons.settings,
            title: 'Ayarlar',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),

          Container(
            height: 50.0,

            child: const Center(
              child: Text(
                'Libris v1.0',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeftBarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const LeftBarItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        focusColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(icon), const SizedBox(height: 8.0), Text(title)],
            ),
          ),
        ),
      ),
    );
  }
}

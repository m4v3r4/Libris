import 'package:flutter/material.dart';
import 'package:libris/features/books/screen/book_form_screen.dart';
import 'package:libris/features/loans/screen/loan_form_screen.dart';
import 'package:libris/features/loans/screen/active_loans_screen.dart';
import 'package:libris/features/loans/screen/loan_list_screen.dart';
import 'package:libris/features/members/screens/member_form_screen.dart';

class QuickMenu extends StatefulWidget {
  @override
  _QuickMenuState createState() => _QuickMenuState();
}

class _QuickMenuState extends State<QuickMenu> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'Hızlı Menu',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ListView(
                shrinkWrap: true,

                children: [
                  ListTile(
                    title: Text("Kitap Ekle"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookFormScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: Text("Emanet Ver"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoanFormScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: Text("Teslim Al"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoanListScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: Text("Yeni Üye"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemberFormScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:libris/features/home/screens/widgets/home_book.dart';
import 'package:libris/features/home/screens/widgets/home_members.dart';
import 'package:libris/features/home/screens/widgets/left_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Libris Kütüphane Sistemi'),

        centerTitle: true,
      ),
      body: Row(
        children: [
          Expanded(flex: 1, child: Leftbar()),
          Expanded(
            flex: 8,
            child: Column(
              children: [
                Expanded(child: HomeMembers()),
                Expanded(child: Center(child: Text('Diger Alan'))),
              ],
            ),
          ),
          Expanded(
            flex: 8,
            child: Column(
              children: [
                Expanded(child: HomeBook()),
                Expanded(child: Center(child: Text('Diger Alan'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/home/screens/widgets/category_analysis_widget.dart';
import 'package:libris/features/home/screens/widgets/home_book.dart';
import 'package:libris/features/home/screens/widgets/home_members.dart';
import 'package:libris/features/home/screens/widgets/left_bar.dart';
import 'package:libris/features/settings/services/category_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final categoryService = CategoryService(
      () => DatabaseHelper.instance.database,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Libris Kütüphane Sistemi'),

        centerTitle: true,
      ),
      body: Row(
        children: [
          Expanded(flex: 2, child: Leftbar()),
          Expanded(
            flex: 8,
            child: Column(
              children: [
                Expanded(child: Center(child: Text('Diger Alan A'))),
                Expanded(
                  child: FutureBuilder(
                    future: categoryService.init().then(
                      (_) => categoryService.getCategoriesWithStats(),
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return SingleChildScrollView(
                        child: CategoryAnalysisWidget(
                          categoryStats:
                              snapshot.data as List<Map<String, dynamic>>,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(child: HomeMembers()),

                Expanded(child: Center(child: Text('Diger Alan B'))),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(child: HomeBook()),
                Expanded(child: Center(child: Text('Diger Alan C'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

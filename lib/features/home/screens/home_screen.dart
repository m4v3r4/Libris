import 'package:flutter/material.dart';

import 'package:libris/features/books/screen/book_list_screen.dart';
import 'package:libris/features/home/screens/widgets/category_analysis_widget.dart';
import 'package:libris/features/home/screens/widgets/home_book.dart';
import 'package:libris/features/home/screens/widgets/home_loan.dart';
import 'package:libris/features/home/screens/widgets/home_members.dart';
import 'package:libris/features/home/screens/widgets/left_bar.dart';
import 'package:libris/features/home/screens/widgets/notification_widget.dart';
import 'package:libris/features/home/screens/widgets/quick_menu.dart';
import 'package:libris/features/loans/screen/loan_list_screen.dart';
import 'package:libris/features/members/screens/members_list_screen.dart';
import 'package:libris/features/settings/screen/category_manager_screen.dart';
import 'package:libris/features/settings/screen/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const desktopBreakpoint = 1200.0;
  static const tabletBreakpoint = 820.0;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LeftbarDestination? _selected;

  void _openSection(LeftbarDestination destination) {
    setState(() {
      _selected = destination;
    });
  }

  void _closeSection() {
    setState(() {
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showDesktopSidebar = width >= HomeScreen.desktopBreakpoint;

    return Scaffold(
      drawer: showDesktopSidebar
          ? null
          : Drawer(
              width: 260,
              child: Leftbar(
                selected: _selected,
                onSelect: (destination) {
                  Navigator.pop(context);
                  _openSection(destination);
                },
              ),
            ),
      appBar: AppBar(
        title: const Text('Libris Kutuphane Sistemi'),
        centerTitle: true,
      ),
      body: showDesktopSidebar
          ? Row(
              children: [
                SizedBox(
                  width: 230,
                  child: Leftbar(
                    selected: _selected,
                    onSelect: _openSection,
                  ),
                ),
                Expanded(
                  child: _selected == null
                      ? const _DashboardBody()
                      : _EmbeddedSection(
                          destination: _selected!,
                          onClose: _closeSection,
                        ),
                ),
              ],
            )
          : (_selected == null
                ? const _DashboardBody()
                : _EmbeddedSection(
                    destination: _selected!,
                    onClose: _closeSection,
                  )),
    );
  }
}

class _EmbeddedSection extends StatelessWidget {
  final LeftbarDestination destination;
  final VoidCallback onClose;

  const _EmbeddedSection({required this.destination, required this.onClose});

  @override
  Widget build(BuildContext context) {
    switch (destination) {
      case LeftbarDestination.books:
        return BookListScreen(embedded: true, onClose: onClose);
      case LeftbarDestination.members:
        return MembersListScreen(embedded: true, onClose: onClose);
      case LeftbarDestination.loans:
        return LoanListScreen(embedded: true, onClose: onClose);
      case LeftbarDestination.categories:
        return CategoryManagerScreen(embedded: true, onClose: onClose);
      case LeftbarDestination.settings:
        return SettingsScreen(embedded: true, onClose: onClose);
    }
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < HomeScreen.tabletBreakpoint) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          SizedBox(height: 340, child: HomeLoan()),
          SizedBox(height: 420, child: CategoryAnalysisWidget()),
          SizedBox(height: 340, child: HomeMembers()),
          SizedBox(height: 340, child: HomeBook()),
          SizedBox(height: 290, child: QuickMenu()),
          SizedBox(height: 290, child: NotificationWidget()),
        ],
      );
    }

    final columns = width >= HomeScreen.desktopBreakpoint ? 3 : 2;
    final itemHeight = width >= HomeScreen.desktopBreakpoint ? 360.0 : 380.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final totalSpacing = spacing * (columns + 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;
        final ratio = itemWidth / itemHeight;

        return GridView.count(
          crossAxisCount: columns,
          padding: const EdgeInsets.all(spacing),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: ratio,
          children: const [
            HomeLoan(),
            CategoryAnalysisWidget(),
            HomeMembers(),
            HomeBook(),
            QuickMenu(),
            NotificationWidget(),
          ],
        );
      },
    );
  }
}


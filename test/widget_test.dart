// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:libris/common/providers/database_provider.dart';
import 'package:libris/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.setSurfaceSize(const Size(1600, 900));

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => DatabaseProvider())],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Libris'), findsWidgets);

    await binding.setSurfaceSize(null);
  });
}

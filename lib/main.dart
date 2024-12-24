import 'dart:io';

import 'package:flutter/material.dart';
import 'package:libris/Pages/HomePage.dart';
import 'package:libris/Service/DatabaseHelper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // FFI veritabanı bağlantısını başlatıyoruz
  databaseFactory = databaseFactoryFfi;

  // Veritabanını başlatıyoruz
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }
  await DatabaseHelper().database; // Veritabanını başlat

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LİBRİS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: HomePage(),
    );
  }
}

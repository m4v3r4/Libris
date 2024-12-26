import 'dart:io';
import 'package:flutter/material.dart';
import 'package:libris/Pages/HomePage.dart';
import 'package:libris/Service/DatabaseHelper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // Tema verisini SharedPreferences'ten yükle
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LİBRİS',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? darkThemeData : lightThemeData,
      home: HomePage(),
    );
  }
}

// Karanlık tema
ThemeData darkThemeData = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
    contrastLevel: 1,
  ),
  appBarTheme: AppBarTheme(
    color: Colors.red,
  ),
);

// Açık tema
ThemeData lightThemeData = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    contrastLevel: 1,
  ),
  appBarTheme: AppBarTheme(
    color: Colors.red,
  ),
);

// Kırmızı, beyaz ve sarı karışımı için bir renk
Color seedColor = Color.lerp(Colors.red, Colors.amber.shade200, 0.5)!
    .withOpacity(1.0); // Opaklık

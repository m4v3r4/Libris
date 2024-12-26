import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libris/Class/CustomBook.dart';
import 'package:libris/Pages/HomePage.dart';
import 'package:libris/Service/LibraryService.dart';
import 'package:libris/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false; // Başlangıçta açık tema

  // Tema verisini SharedPreferences'e kaydetmek için bir fonksiyon
  void _saveThemeToPrefs(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  // Tema verisini SharedPreferences'ten yüklemek için bir fonksiyon
  void _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkMode =
        prefs.getBool('isDarkMode') ?? false; // Varsayılan olarak false
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadThemeFromPrefs(); // Uygulama başladığında tema tercihini yükle
  }

  // Tema değişikliğini yönetmek için fonksiyon
  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });

    _saveThemeToPrefs(value); // Tema değişikliği kaydedilsin
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Hesap Bilgileri'),
            onTap: () {
              // Hesap bilgileri sayfasına yönlendirme
              print('Hesap Bilgileri');
            },
          ),
          ListTile(
            leading: Icon(Icons.import_export),
            title: Text('Kitapları Dışa Aktar'),
            onTap: () async {
              List<CustomBook> books =
                  await LibraryService().bookDao.getAllBooks();

              // Kullanıcıdan dosya seçmesini iste
              String? inputPath = await FilePicker.platform.pickFiles(
                dialogTitle: 'Kitapları içe aktarmak için bir dosya seçin',
                type: FileType.custom,
                allowedExtensions: ['xlsx'],
              ).then((result) => result?.files.single.path);

              if (inputPath != null) {
                LibraryService().exportBooksToExcel(inputPath, books);
              } else {
                // Kullanıcı iptal ettiyse bir şey yapmayın
                print("Kullanıcı dosya seçimi iptal etti.");
              }

              // Bildirimler ayarı sayfasına yönlendirme
              print('Bildirimler');
            },
          ),
          ListTile(
            leading: Icon(Icons.import_export_outlined),
            title: Text('Kitapları İçe Aktar'),
            onTap: () async {
              // Kullanıcıdan dosya seçmesini iste
              String? inputPath = await FilePicker.platform.pickFiles(
                dialogTitle: 'Kitapları içe aktarmak için bir dosya seçin',
                type: FileType.custom,
                allowedExtensions: ['xlsx'],
              ).then((result) => result?.files.single.path);

              if (inputPath != null) {
                LibraryService().importBooksFromExcel(inputPath);
              } else {
                // Kullanıcı iptal ettiyse bir şey yapmayın
                print("Kullanıcı dosya seçimi iptal etti.");
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Dil'),
            onTap: () {
              // Dil seçimi sayfasına yönlendirme
              print('Dil');
            },
          ),
          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('Karanlık Tema'),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _toggleTheme,
              activeColor: Colors.grey,
            ),
            onTap: () {
              // Switch'in kontrolü burada yapılır, kullanıcı dokunduğunda değer değişir
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Yardım ve Destek'),
            onTap: () {
              launch('https://sberkayu.com.tr');
              // Yardım ve destek sayfasına yönlendirme
              print('Yardım ve Destek');
            },
          ),
        ],
      ),
    );
  }
}

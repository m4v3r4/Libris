import 'package:flutter/material.dart';
import 'package:libris/Class/CustomUser.dart';
import 'package:libris/Service/UserDao.dart';
import 'package:libris/Class/Loan.dart'; // Eğer kitap ödünç bilgisi de eklenmesi gerekiyorsa

class AddUserPage extends StatefulWidget {
  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final UserDao _userDao = UserDao();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController facultyController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();

  // Yeni kullanıcıyı ekle
  void _addUser() async {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneNumberController.text.isEmpty) {
      // Boş alanlar kontrolü
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen tüm zorunlu alanları doldurun.'),
      ));
      return;
    }

    // Yeni CustomUser nesnesi oluştur
    CustomUser newUser = CustomUser(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(), // Benzersiz ID oluşturmak için timestamp kullanabiliriz
      firstname: firstNameController.text,
      lastname: lastNameController.text,
      email: emailController.text,
      phoneNumber: phoneNumberController.text,
      borrowedBooksIds: [], // Başlangıçta ödünç kitap yok
      studentId:
          studentIdController.text.isNotEmpty ? studentIdController.text : null,
      faculty:
          facultyController.text.isNotEmpty ? facultyController.text : null,
      department: departmentController.text.isNotEmpty
          ? departmentController.text
          : null,
    );

    // Kullanıcıyı veritabanına kaydet
    await _userDao.insertUser(newUser);

    // Başarılı ekleme sonrası mesaj ve sayfayı kapat
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Kullanıcı başarıyla eklendi!'),
    ));

    // Sayfayı kapat
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Kullanıcı Ekle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ad alanı
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'Ad',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Soyad alanı
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Soyad',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // E-posta alanı
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),

              // Telefon numarası alanı
              TextField(
                controller: phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),

              // Öğrenci ID alanı (isteğe bağlı)
              TextField(
                controller: studentIdController,
                decoration: InputDecoration(
                  labelText: 'Öğrenci ID (isteğe bağlı)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Fakülte alanı (isteğe bağlı)
              TextField(
                controller: facultyController,
                decoration: InputDecoration(
                  labelText: 'Fakülte (isteğe bağlı)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Bölüm alanı (isteğe bağlı)
              TextField(
                controller: departmentController,
                decoration: InputDecoration(
                  labelText: 'Bölüm (isteğe bağlı)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 32),

              // Kaydet butonu
              ElevatedButton(
                onPressed: _addUser,
                child: Text('Kullanıcıyı Ekle'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

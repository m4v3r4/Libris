import 'package:flutter/material.dart';
import 'package:libris/Class/CustomUser.dart';
import 'package:libris/Pages/UserPages/AddUserPage.dart';
import 'package:libris/Service/UserDao.dart';

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final UserDao _userDao = UserDao();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController facultyController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();

  // Filtre seçenekleri
  String selectedFilter = 'Tümü'; // Filtre seçeneği
  List<CustomUser> users = [];
  List<CustomUser> filteredUsers = [];

  // Kullanıcıları veritabanından al
  Future<void> loadUsers() async {
    users = await _userDao.getAllUsers();
    applyFilters();
  }

  // Arama ve filtreleme işlemleri
  void applyFilters() {
    String query = searchController.text.toLowerCase();
    String firstName = firstNameController.text.toLowerCase();
    String lastName = lastNameController.text.toLowerCase();
    String faculty = facultyController.text.toLowerCase();
    String department = departmentController.text.toLowerCase();

    setState(() {
      filteredUsers = users.where((user) {
        bool matchesQuery = user.firstname.toLowerCase().contains(firstName) &&
            user.lastname.toLowerCase().contains(lastName);

        // Aktif/Pasif filtreleme (ödünç kitap var mı?)
        bool matchesFilter = selectedFilter == 'Tümü' ||
            (selectedFilter == 'Aktif' && user.borrowedBooksIds.isNotEmpty) ||
            (selectedFilter == 'Pasif' && user.borrowedBooksIds.isEmpty);

        bool matchesFaculty =
            faculty.isEmpty || user.faculty!.toLowerCase().contains(faculty) ??
                false;
        bool matchesDepartment = department.isEmpty ||
                user.department!.toLowerCase().contains(department) ??
            false;

        return matchesQuery &&
            matchesFilter &&
            matchesFaculty &&
            matchesDepartment;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    loadUsers(); // Sayfa ilk açıldığında kullanıcıları yükle
  }

  void handleMenuItem(String value) {
    switch (value) {
      case 'add':
        // Yeni kitap ekleme işlemi
        print('Yeni kitap ekle');
        break;
      case 'delete':
        // Kitap silme işlemi
        print('Kitap sil');
        break;
      // Diğer işlemler burada tanımlanabilir
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanıcılar'),
        actions: [
          PopupMenuButton<String>(
            onSelected: handleMenuItem,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddUserPage(),
                        ));
                  },
                  value: 'add',
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Yeni Kullanıcı Ekle'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Kullanıcı Sil'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Sol Kısım: Arama ve Filtreleme
            Expanded(
              flex: 3,
              child: Card(
                elevation: 5,
                margin: EdgeInsets.only(right: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ad (firstName) ve Soyad (lastName) Filtreleme
                      TextField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          labelText: 'Ad Filtrele',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          applyFilters();
                        },
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Soyad Filtrele',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          applyFilters();
                        },
                      ),
                      SizedBox(height: 16),

                      // Fakülte Filtreleme
                      TextField(
                        controller: facultyController,
                        decoration: InputDecoration(
                          labelText: 'Fakülte Filtrele',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          applyFilters();
                        },
                      ),
                      SizedBox(height: 16),

                      // Bölüm Filtreleme
                      TextField(
                        controller: departmentController,
                        decoration: InputDecoration(
                          labelText: 'Bölüm Filtrele',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          applyFilters();
                        },
                      ),
                      SizedBox(height: 16),

                      // Durum Filtreleme (Aktif/Pasif)
                      DropdownButtonFormField<String>(
                        value: selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Durum Filtrele',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Tümü', 'Aktif', 'Pasif']
                            .map((filter) => DropdownMenuItem(
                                  value: filter,
                                  child: Text(filter),
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedFilter = newValue!;
                          });
                          applyFilters(); // Filtre değiştiğinde tekrar filtrele
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sağ Kısım: Kullanıcılar Listesi
            Expanded(
              flex: 7,
              child: Card(
                elevation: 5,
                child: filteredUsers.isNotEmpty
                    ? ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return ListTile(
                            title: Text('${user.firstname} ${user.lastname}'),
                            subtitle: Text(user.email),
                            trailing: Text(user.borrowedBooksIds.isNotEmpty
                                ? 'Ödünç Kitap Var'
                                : 'Ödünç Kitap Yok'),
                            onTap: () {
                              // Kullanıcıya tıklandığında yapılacak işlemler
                              // Örneğin, kullanıcı detay sayfasına yönlendirme
                            },
                          );
                        },
                      )
                    : Center(child: Text('Kullanıcı bulunamadı.')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

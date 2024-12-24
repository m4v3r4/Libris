import 'dart:convert'; // JSON işlemleri için import ekliyoruz

class CustomUser {
  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final String phoneNumber;
  final List<String> borrowedBooksIds; // List<String> olarak güncellendi
  final String? studentId;
  final String? faculty;
  final String? department;

  CustomUser({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phoneNumber,
    required this.borrowedBooksIds,
    this.studentId,
    this.faculty,
    this.department,
  });

  // JSON'dan CustomUser nesnesi oluşturma
  factory CustomUser.fromJson(Map<String, dynamic> json) {
    return CustomUser(
      id: json['id'] ?? '',
      firstname: json['firstname'] ?? 'Bilinmeyen',
      lastname: json['lastname'] ?? 'Bilinmeyen',
      email: json['email'] ?? 'Bilinmeyen Email',
      phoneNumber: json['phoneNumber'] ?? 'Bilinmeyen Telefon',
      borrowedBooksIds: json['borrowedBooksIds'] != null
          ? List<String>.from(jsonDecode(json['borrowedBooksIds']))
          : [],
      studentId: json['studentId'],
      faculty: json['faculty'],
      department: json['department'],
    );
  }

  // CustomUser nesnesini Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'phoneNumber': phoneNumber,
      'borrowedBooksIds':
          jsonEncode(borrowedBooksIds), // List'i JSON string'e dönüştürüyoruz
      'studentId': studentId,
      'faculty': faculty,
      'department': department,
    };
  }
}

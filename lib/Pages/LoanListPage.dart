import 'package:flutter/material.dart';
import 'package:libris/Service/DatabaseHelper.dart';
import 'package:libris/Service/LoanDao.dart';
import 'package:libris/Class/Loan.dart';
import 'package:intl/intl.dart';

class LoanListPage extends StatefulWidget {
  @override
  _LoanListPageState createState() => _LoanListPageState();
}

class _LoanListPageState extends State<LoanListPage> {
  final LoanDao loanDao = LoanDao();
  List<Loan> loans = [];
  List<Loan> filteredLoans = [];
  String searchQuery = '';
  DateTime? selectedDate;
  bool showExpiredOnly = false;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  // Loans verilerini yükleme
  Future<void> _loadLoans() async {
    loans = await loanDao.getAllLoans();
    _applyFilters();
  }

  // Filtreleri uygula
  void _applyFilters() {
    filteredLoans = loans.where((loan) {
      // Kullanıcı adı ve soyadı ile arama
      bool matchesSearch = loan.userId.contains(searchQuery) ||
          loan.userFirstName.contains(searchQuery) ||
          loan.userLastName.contains(searchQuery);

      // Kitap adı ile arama
      bool matchesBookName = loan.bookName.contains(searchQuery);

      // Tarih filtresi
      bool matchesDate = selectedDate == null ||
          loan.loanDate.isBefore(selectedDate!.add(Duration(days: 1))) &&
              loan.loanDate.isAfter(selectedDate!.subtract(Duration(days: 1)));

      // Geçmişteki ödünçler
      bool matchesExpired = !showExpiredOnly ||
          (loan.returnDate != null &&
              loan.returnDate!.isBefore(DateTime.now()));

      return (matchesSearch || matchesBookName) &&
          matchesDate &&
          matchesExpired;
    }).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Loan Listesi')),
      body: Row(
        children: [
          // Sol tarafta arama ve filtreleme kısmı
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arama kutusu
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Kullanıcı Adı, Soyadı veya Kitap Adı ile Ara',
                      hintText: 'Arama yapın...',
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                      _applyFilters();
                    },
                  ),
                  SizedBox(height: 16),

                  // Tarih filtresi
                  ListTile(
                    title: Text(
                        'Tarih Filtresi: ${selectedDate == null ? 'Seçilmedi' : DateFormat('yyyy-MM-dd').format(selectedDate!)}'),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                        _applyFilters();
                      }
                    },
                  ),
                  SizedBox(height: 16),

                  // Geçmişteki ödünçleri göster
                  SwitchListTile(
                    title: Text('Geçmişteki ödünçleri göster'),
                    value: showExpiredOnly,
                    onChanged: (value) {
                      setState(() {
                        showExpiredOnly = value;
                      });
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Sağ tarafta Loan sonuçları
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: filteredLoans.isEmpty
                  ? Center(child: Text('Hiçbir ödünç bulunamadı'))
                  : ListView.builder(
                      itemCount: filteredLoans.length,
                      itemBuilder: (context, index) {
                        final loan = filteredLoans[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                                'Kullanıcı: ${loan.userFirstName} ${loan.userLastName} - Kitap: ${loan.bookName}'),
                            subtitle: Text(
                                'Ödünç Verme Tarihi: ${DateFormat('yyyy-MM-dd').format(loan.loanDate)}\n'
                                'İade Tarihi: ${loan.returnDate == null ? 'Henüz iade edilmedi' : DateFormat('yyyy-MM-dd').format(loan.returnDate!)}'),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:libris/Class/CustomBook.dart';
import 'package:libris/Class/CustomUser.dart';
import 'package:libris/Pages/LoanPages/LoanDetailPage.dart';
import 'package:libris/Service/BookDao.dart';
import 'package:libris/Service/DatabaseHelper.dart';
import 'package:libris/Service/LoanDao.dart';
import 'package:libris/Class/Loan.dart';
import 'package:intl/intl.dart';
import 'package:libris/Service/UserDao.dart';

class LoanListPage extends StatefulWidget {
  @override
  _LoanListPageState createState() => _LoanListPageState();
}

class _LoanListPageState extends State<LoanListPage> {
  final LoanDao loanDao = LoanDao();
  List<Loan> loans = [];
  List<Loan> filteredLoans = [];
  String searchQuery = '';
  bool showExpiredOnly = false;
  bool showReturnedOnly = false; // Teslim alınanlar filtresi
  String selectedDuration = 'Temizle'; // Varsayılan seçilen süre
  String selectedStatus =
      'Hepsi'; // Durum seçeneği (Teslim Alınan, Teslim Alınmayan, Hepsi)

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

  void _applyFilters() {
    filteredLoans = loans.where((loan) {
      // Kullanıcı adı ve soyadı ile arama
      bool matchesSearch = loan.userId.contains(searchQuery) ||
          loan.userFirstName.contains(searchQuery) ||
          loan.userLastName.contains(searchQuery);

      // Kitap adı ile arama
      bool matchesBookName = loan.bookName.contains(searchQuery);

      // Teslim süresi filtresi
      bool matchesDuration = _matchesDuration(loan);

      // Teslim alınanlar filtresi
      bool matchesReturned = !showReturnedOnly || loan.returnDate != null;

      // Geçmişteki ödünçler
      bool matchesExpired = !showExpiredOnly ||
          (loan.returnDate != null &&
              loan.returnDate!.isBefore(DateTime.now()));

      // Durum filtresi: "Teslim Alınan" ya da "Teslim Alınmayan"
      bool matchesStatus = (selectedStatus == 'Hepsi') ||
          (selectedStatus == 'Teslim Alınan' && loan.returnDate != null) ||
          (selectedStatus == 'Teslim Alınmayan' && loan.returnDate == null);

      return (matchesSearch || matchesBookName) &&
          matchesDuration &&
          matchesReturned &&
          matchesExpired &&
          matchesStatus;
    }).toList();
    setState(() {});
  }

  // Teslim süresi filtresi kontrolü
  bool _matchesDuration(Loan loan) {
    final now = DateTime.now();
    final loanDate = loan.loanDate;
    Duration duration;

    switch (selectedDuration) {
      case '1 hafta':
        duration = Duration(days: 7);
        break;
      case '2 hafta':
        duration = Duration(days: 14);
        break;
      case '1 ay':
        duration = Duration(days: 30);
        break;
      case 'Temizle':
        duration = Duration(days: 0);
        break;
      default:
        duration = Duration(days: 0); // Varsayılan olarak 1 hafta
    }

    // Eğer ödünç verilen kitap teslim süresi geçtiyse, uygun filtreleme yapılır
    return loanDate.add(duration).isBefore(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ödünç Listesi')),
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

                  // Teslim süresi filtresi
                  ListTile(
                    title: Text('Teslim Süresi: $selectedDuration'),
                    onTap: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          return SimpleDialog(
                            title: Text('Teslim Süresi Seçin'),
                            children: <Widget>[
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.pop(context, 'Temizle');
                                },
                                child: Text('Temizle'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.pop(context, '1 hafta');
                                },
                                child: Text('1 hafta'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.pop(context, '2 hafta');
                                },
                                child: Text('2 hafta'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.pop(context, '1 ay');
                                },
                                child: Text('1 ay'),
                              ),
                            ],
                          );
                        },
                      );
                      if (result != null && result != selectedDuration) {
                        setState(() {
                          selectedDuration = result;
                        });
                        _applyFilters();
                      }
                    },
                  ),
                  SizedBox(height: 16),

                  // Durum filtresi: Teslim Alınan, Teslim Alınmayan
                  ListTile(
                    title: Text('Durum: $selectedStatus'),
                    onTap: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          return SimpleDialog(
                            title: Text('Durum Seçin'),
                            children: <Widget>[
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.pop(context, 'Hepsi');
                                },
                                child: Text('Hepsi'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.pop(context, 'Teslim Alınan');
                                },
                                child: Text('Teslim Alınan'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.pop(context, 'Teslim Alınmayan');
                                },
                                child: Text('Teslim Alınmayan'),
                              ),
                            ],
                          );
                        },
                      );
                      if (result != null && result != selectedStatus) {
                        setState(() {
                          selectedStatus = result;
                        });
                        _applyFilters();
                      }
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
                            onTap: () async {
                              CustomUser? user =
                                  await UserDao().getUserById(loan.userId);
                              CustomBook? book =
                                  await BookDao().getBookById(loan.bookId);

                              // Push to LoanDetailsPage and wait for a result
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoanDetailsPage(
                                    loan: loan,
                                    user: user!,
                                    book: book!,
                                  ),
                                ),
                              );

                              // If the result is true (indicating that we need to reload data)
                              if (result == true) {
                                _loadLoans(); // Reload loans
                              }
                            },
                            title: Text(
                                'Kullanıcı: ${loan.userFirstName} ${loan.userLastName} - Kitap: ${loan.bookName}'),
                            subtitle: Text(
                                'Ödünç Verme Tarihi: ${DateFormat('yyyy-MM-dd').format(loan.loanDate)}\n'
                                'İade Tarihi: ${loan.returnDate == null ? 'Henüz iade edilmedi' : DateFormat('yyyy-MM-dd').format(loan.returnDate!)}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    onPressed: () {}, icon: Icon(Icons.edit)),
                                IconButton(
                                    onPressed: () async {
                                      final confirmed =
                                          await _showDeleteConfirmationDialog(
                                              context);
                                      if (confirmed) {
                                        await _handleDeleteLoan(loan);
                                      }
                                    },
                                    icon: Icon(Icons.remove, color: Colors.red))
                              ],
                            ),
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

  Future<void> _handleDeleteLoan(Loan loan) async {
    final db = await DatabaseHelper().database;

    try {
      await db.transaction((txn) async {
        // Loan kaydını sil
        await txn.delete(
          'loans',
          where: 'id = ?',
          whereArgs: [loan.id],
        );
      });

      setState(() {
        loans.removeWhere((l) => l.id == loan.id);
        filteredLoans.removeWhere((l) => l.id == loan.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan başarıyla silindi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Sil'),
              content:
                  Text('Bu ödünç kaydını silmek istediğinize emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Hayır'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Evet'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

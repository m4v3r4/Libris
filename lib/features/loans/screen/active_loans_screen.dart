import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/loans/screen/loan_return_screen.dart';

class ActiveLoansScreen extends StatefulWidget {
  const ActiveLoansScreen({super.key});

  @override
  State<ActiveLoansScreen> createState() => _ActiveLoansScreenState();
}

class _ActiveLoansScreenState extends State<ActiveLoansScreen> {
  final DatabaseHelper _loanService = DatabaseHelper.instance;
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);
    final loans = await _loanService.getActiveLoans();
    if (mounted) {
      setState(() {
        _loans = loans.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emanetteki Kitaplar')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
          ? const Center(child: Text('Emanette kitap bulunmuyor.'))
          : ListView.separated(
              itemCount: _loans.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final loan = _loans[index];
                return ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: Text(loan['bookTitle'] ?? 'Bilinmeyen Kitap'),
                  subtitle: Text(
                    '${loan['memberName']} - Son Tarih: ${loan['dueDate']}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoanReturnScreen(loan: loan),
                      ),
                    );
                    _loadLoans(); // Refresh list after returning
                  },
                );
              },
            ),
    );
  }
}

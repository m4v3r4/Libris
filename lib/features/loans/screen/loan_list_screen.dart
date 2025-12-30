import 'package:flutter/material.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/loans/screen/loan_form_screen.dart';
import 'package:libris/features/loans/widgets/loan_card.dart';

enum LoanFilterStatus { all, active, overdue, returned }

class LoanListScreen extends StatefulWidget {
  const LoanListScreen({super.key});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> {
  final DatabaseHelper _loanService = DatabaseHelper.instance;
  List<Loan> _allLoans = [];
  List<Loan> _filteredLoans = [];
  LoanFilterStatus _filterStatus = LoanFilterStatus.all;
  DateTimeRange? _dateRange;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);
    final loans = await _loanService.getLoans();
    if (mounted) {
      setState(() {
        _allLoans = loans;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Loan> result = _allLoans;

    // Durum Filtresi
    switch (_filterStatus) {
      case LoanFilterStatus.active:
        result = result.where((l) => l.returnedAt == null).toList();
        break;
      case LoanFilterStatus.overdue:
        final now = DateTime.now();
        result = result
            .where((l) => l.returnedAt == null && now.isAfter(l.dueDate))
            .toList();
        break;
      case LoanFilterStatus.returned:
        result = result.where((l) => l.returnedAt != null).toList();
        break;
      case LoanFilterStatus.all:
        break;
    }

    // Tarih Aralığı Filtresi (Veriliş Tarihine Göre)
    if (_dateRange != null) {
      result = result.where((l) {
        return l.loanDate.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            l.loanDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    setState(() {
      _filteredLoans = result;
    });
  }

  Future<void> _openForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoanFormScreen()),
    );
    _loadLoans();
  }

  Future<void> _returnLoan(Loan loan) async {
    await _loanService.returnLoan(loan.id!);
    _loadLoans();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _applyFilters();
      });
    }
  }

  String _getStatusLabel(LoanFilterStatus status) {
    switch (status) {
      case LoanFilterStatus.all:
        return 'Tümü';
      case LoanFilterStatus.active:
        return 'Emanette';
      case LoanFilterStatus.overdue:
        return 'Gecikmiş';
      case LoanFilterStatus.returned:
        return 'İade Edilen';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emanetler')),
      body: Column(
        children: [
          // Filtreleme Alanı
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                InputChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _dateRange == null
                        ? 'Tarih Aralığı'
                        : '${_dateRange!.start.day}.${_dateRange!.start.month} - ${_dateRange!.end.day}.${_dateRange!.end.month}',
                  ),
                  onPressed: _pickDateRange,
                  onDeleted: _dateRange != null
                      ? () {
                          setState(() {
                            _dateRange = null;
                            _applyFilters();
                          });
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                ...LoanFilterStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(_getStatusLabel(status)),
                      selected: _filterStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = status;
                          _applyFilters();
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLoans.isEmpty
                ? const Center(child: Text('Kayıt bulunamadı'))
                : ListView.builder(
                    itemCount: _filteredLoans.length,
                    itemBuilder: (context, index) {
                      final loan = _filteredLoans[index];
                      return LoanCard(
                        loan: loan,
                        onReturn: () => _returnLoan(loan),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

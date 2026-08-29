import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/common/providers/database_provider.dart';
import 'package:libris/common/widgets/section_toolbar.dart';
import 'package:libris/features/loans/screen/loan_form_screen.dart';
import 'package:libris/features/loans/widgets/loan_card.dart';
import 'package:provider/provider.dart';

enum LoanFilterStatus { all, active, overdue, returned }

class LoanListScreen extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onClose;

  const LoanListScreen({super.key, this.embedded = false, this.onClose});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> {
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
    final dbProvider = context.read<DatabaseProvider>();
    setState(() => _isLoading = true);
    final loans = await dbProvider.getLoans();

    if (mounted) {
      setState(() {
        _allLoans = loans;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Loan> result = List<Loan>.from(_allLoans);

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

    if (_dateRange != null) {
      result = result.where((l) {
        return l.loanDate.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            l.loanDate.isBefore(
              _dateRange!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    result.sort((a, b) => b.loanDate.compareTo(a.loanDate));
    _filteredLoans = result;
  }

  int _countFor(LoanFilterStatus status) {
    final now = DateTime.now();
    switch (status) {
      case LoanFilterStatus.all:
        return _allLoans.length;
      case LoanFilterStatus.active:
        return _allLoans.where((loan) => loan.returnedAt == null).length;
      case LoanFilterStatus.overdue:
        return _allLoans
            .where(
              (loan) => loan.returnedAt == null && now.isAfter(loan.dueDate),
            )
            .length;
      case LoanFilterStatus.returned:
        return _allLoans.where((loan) => loan.returnedAt != null).length;
    }
  }

  Future<void> _openForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoanFormScreen()),
    );
    await _loadLoans();
  }

  Future<void> _returnLoan(Loan loan) async {
    if (loan.id == null) return;
    await context.read<DatabaseProvider>().returnLoan(loan.id!);
    await _loadLoans();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      helpText: l10n('Tarih aralığı seçin', 'Select date range'),
      cancelText: l10n('İptal', 'Cancel'),
      confirmText: l10n('Uygula', 'Apply'),
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
        return l10n('Tümü', 'All');
      case LoanFilterStatus.active:
        return l10n('Emanette', 'Active');
      case LoanFilterStatus.overdue:
        return l10n('Gecikmiş', 'Overdue');
      case LoanFilterStatus.returned:
        return l10n('İade edilen', 'Returned');
    }
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _clearFilters() {
    setState(() {
      _filterStatus = LoanFilterStatus.all;
      _dateRange = null;
      _applyFilters();
    });
  }

  void _close() {
    if (widget.embedded) {
      widget.onClose?.call();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasFilters =
        _filterStatus != LoanFilterStatus.all || _dateRange != null;

    return Scaffold(
      body: Column(
        children: [
          SectionToolbar(
            title: l10n('Emanetler', 'Loans'),
            subtitle: l10n(
              'Ödünç, gecikme ve iade hareketlerini takip edin.',
              'Track lending, overdue, and return activity.',
            ),
            icon: Icons.swap_horiz_rounded,
            count: _filteredLoans.length,
            onClose: _close,
            leadingIcon:
                widget.embedded ? Icons.close_rounded : Icons.arrow_back_rounded,
            leadingTooltip:
                widget.embedded ? l10n('Kapat', 'Close') : l10n('Geri', 'Back'),
            actions: [
              IconButton(
                onPressed: _loadLoans,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n('Yenile', 'Refresh'),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            color: scheme.surface.withValues(alpha: 0.45),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InputChip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(
                    _dateRange == null
                        ? l10n('Tarih aralığı', 'Date range')
                        : '${_formatShortDate(_dateRange!.start)} – ${_formatShortDate(_dateRange!.end)}',
                  ),
                  onPressed: _pickDateRange,
                  onDeleted: _dateRange == null
                      ? null
                      : () {
                          setState(() {
                            _dateRange = null;
                            _applyFilters();
                          });
                        },
                ),
                ...LoanFilterStatus.values.map((status) {
                  return FilterChip(
                    label: Text(
                      '${_getStatusLabel(status)}  ${_countFor(status)}',
                    ),
                    selected: _filterStatus == status,
                    onSelected: (_) {
                      setState(() {
                        _filterStatus = status;
                        _applyFilters();
                      });
                    },
                  );
                }),
                if (hasFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: Text(l10n('Filtreleri Temizle', 'Clear Filters')),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLoans.isEmpty
                    ? SectionEmptyState(
                        icon: _allLoans.isEmpty
                            ? Icons.swap_horizontal_circle_outlined
                            : Icons.filter_alt_off_outlined,
                        title: _allLoans.isEmpty
                            ? l10n('Henüz emanet kaydı yok', 'No loan records yet')
                            : l10n(
                                'Bu filtrelerle eşleşen kayıt yok',
                                'No records match these filters',
                              ),
                        description: _allLoans.isEmpty
                            ? l10n(
                                'İlk ödünç işlemini başlatarak emanet hareketlerini burada takip edin.',
                                'Start your first lending transaction to track loan activity here.',
                              )
                            : l10n(
                                'Filtreleri değiştirin veya temizleyin.',
                                'Change or clear the filters.',
                              ),
                        actionLabel:
                            _allLoans.isEmpty ? l10n('Emanet Ver', 'Create Loan') : null,
                        onAction: _allLoans.isEmpty ? _openForm : null,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
                        itemCount: _filteredLoans.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n('Emanet Ver', 'Create Loan')),
      ),
    );
  }
}

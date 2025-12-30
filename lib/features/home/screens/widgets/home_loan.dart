import 'package:flutter/material.dart';
import 'package:libris/features/loans/services/loan_service.dart';

class HomeLoan extends StatefulWidget {
  const HomeLoan({super.key});

  @override
  State<HomeLoan> createState() => _HomeLoanState();
}

class _HomeLoanState extends State<HomeLoan>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoanService _loanService = LoanService();

  List<Map<String, dynamic>> _overdueLoans = [];
  List<Map<String, dynamic>> _recentLoans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final overdue = await _loanService.getOverdueLoans();
      final recent = await _loanService.getRecentLoans();
      if (mounted) {
        setState(() {
          _overdueLoans = overdue;
          _recentLoans = recent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,

            tabs: const [
              Tab(text: 'Gecikenler'),
              Tab(text: 'Son İşlemler'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_overdueLoans, isOverdue: true),
                      _buildList(_recentLoans),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> items, {
    bool isOverdue = false,
  }) {
    if (items.isEmpty) {
      return const Center(child: Text('Kayıt bulunamadı.'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final bookTitle = item['bookTitle'] ?? 'Kitap Silinmiş';
        final memberName = item['memberName'] ?? 'Üye Silinmiş';

        IconData icon;
        Color color;
        String subtitle;

        if (isOverdue) {
          final date = item['dueDate'];
          final dateStr = date != null && date.toString().length > 10
              ? date.toString().substring(0, 10)
              : date.toString();
          icon = Icons.warning_amber_rounded;
          color = Colors.red;
          subtitle = '$memberName\nSon Gün: $dateStr';
        } else {
          final isReturned = item['returnedAt'] != null;
          final date = item['updatedAt'];
          final dateStr = date != null && date.toString().length > 16
              ? date.toString().substring(0, 16).replaceFirst('T', ' ')
              : (date?.toString() ?? '');

          if (isReturned) {
            icon = Icons.check_circle_outline;
            color = Colors.green;
            subtitle = 'Teslim Alındı: $memberName\n$dateStr';
          } else {
            icon = Icons.arrow_circle_right_outlined;
            color = Colors.blue;
            subtitle = 'Teslim Edildi: $memberName\n$dateStr';
          }
        }

        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(bookTitle),
          subtitle: Text(subtitle),
          isThreeLine: true,
          dense: true,
        );
      },
    );
  }
}

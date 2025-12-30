import 'package:flutter/material.dart';
import 'package:libris/features/loans/services/loan_service.dart';

class LoanReturnScreen extends StatefulWidget {
  final Map<String, dynamic> loan;

  const LoanReturnScreen({super.key, required this.loan});

  @override
  State<LoanReturnScreen> createState() => _LoanReturnScreenState();
}

class _LoanReturnScreenState extends State<LoanReturnScreen> {
  final LoanService _loanService = LoanService();
  bool _isProcessing = false;

  Future<void> _handleReturn() async {
    setState(() => _isProcessing = true);
    try {
      await _loanService.returnLoan(widget.loan['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kitap başarıyla iade alındı.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    final str = date.toString();
    if (str.length > 10) return str.substring(0, 10);
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    return Scaffold(
      appBar: AppBar(title: const Text('İade İşlemi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan['bookTitle'] ?? '',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Üye: ${loan['memberName']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Veriliş Tarihi: ${_formatDate(loan['loanDate'])}'),
                    Text('Son Teslim Tarihi: ${_formatDate(loan['dueDate'])}'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _isProcessing ? null : _handleReturn,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('TESLİM AL'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }
}

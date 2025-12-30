import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/features/loans/screen/loan_form_screen.dart';

class LoanCard extends StatefulWidget {
  final Loan loan;
  final VoidCallback? onTap;
  final VoidCallback? onReturn;
  final VoidCallback? onEdit;

  const LoanCard({
    super.key,
    required this.loan,
    this.onTap,
    this.onReturn,
    this.onEdit,
  });

  @override
  State<LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<LoanCard> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  String _bookTitle = 'Yükleniyor...';
  String _memberName = 'Yükleniyor...';

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final book = await _databaseHelper.getBookById(widget.loan.bookId);
    final member = await _databaseHelper.getMemberById(widget.loan.memberId);

    if (mounted) {
      setState(() {
        _bookTitle = book?.title ?? 'Silinmiş Kayıt';
        _memberName = member?.name ?? 'Silinmiş Kayıt';
      });
    }
  }

  bool get isReturned => widget.loan.returnedAt != null;
  bool get isOverdue =>
      !isReturned && DateTime.now().isAfter(widget.loan.dueDate);

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isReturned) {
      statusColor = Colors.green;
      statusText = 'İade Edildi';
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = colorScheme.error;
      statusText = 'Gecikmiş';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.orange;
      statusText = 'Emanette';
      statusIcon = Icons.access_time_filled;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Üst Kısım: İkon, Başlıklar ve Durum Etiketi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.book, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _bookTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _memberName,
                                style: TextStyle(color: Colors.grey[700]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              // Alt Kısım: Tarihler ve Aksiyon Butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDateInfo('Veriliş', widget.loan.loanDate),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.grey[400]),
                  _buildDateInfo(
                    'Son Tarih',
                    widget.loan.dueDate,
                    isOverdue: isOverdue,
                  ),

                  // Düzenle Butonu
                  if (widget.onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: widget.onEdit,
                      tooltip: 'Düzenle',
                    ),

                  // Eğer iade edilmemişse ve onReturn fonksiyonu verilmişse butonu göster
                  if (!isReturned && widget.onReturn != null) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: widget.onReturn,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('İade Al'),
                    ),

                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LoanFormScreen(loan: widget.loan),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Düzenle '),
                    ),
                  ] else if (isReturned) ...[
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    _buildDateInfo(
                      'İade',
                      widget.loan.returnedAt!,
                      isSuccess: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateInfo(
    String label,
    DateTime date, {
    bool isOverdue = false,
    bool isSuccess = false,
  }) {
    Color color = Colors.black87;
    if (isOverdue) color = Colors.red;
    if (isSuccess) color = Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          _formatDate(date),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}

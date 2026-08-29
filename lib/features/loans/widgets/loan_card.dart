import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/common/services/database_helper.dart';
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

  String _bookTitle = '';
  String _memberName = '';
  String? _copyCode;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final book = await _databaseHelper.getBookById(widget.loan.bookId);
    final member = await _databaseHelper.getMemberById(widget.loan.memberId);
    final copy = widget.loan.copyId == null
        ? null
        : await _databaseHelper.getBookCopyById(widget.loan.copyId!);

    if (!mounted) return;
    setState(() {
      _bookTitle = book?.title ?? l10n('Silinmiş kayıt', 'Deleted record');
      _memberName = member?.name ?? l10n('Silinmiş kayıt', 'Deleted record');
      _copyCode = copy?.inventoryCode;
    });
  }

  bool get isReturned => widget.loan.returnedAt != null;
  bool get isOverdue =>
      !isReturned && DateTime.now().isAfter(widget.loan.dueDate);

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bookTitle = _bookTitle.isEmpty ? l10n('Yükleniyor...', 'Loading...') : _bookTitle;
    final memberName = _memberName.isEmpty ? l10n('Yükleniyor...', 'Loading...') : _memberName;

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (isReturned) {
      statusColor = scheme.tertiary;
      statusText = l10n('İade edildi', 'Returned');
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (isOverdue) {
      statusColor = scheme.error;
      statusText = l10n('Gecikmiş', 'Overdue');
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = scheme.primary;
      statusText = l10n('Emanette', 'On loan');
      statusIcon = Icons.schedule_rounded;
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _LoanMeta(
                              icon: Icons.person_outline_rounded,
                              text: memberName,
                            ),
                            if (_copyCode != null)
                              _LoanMeta(
                                icon: Icons.inventory_2_outlined,
                                text: _copyCode!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 12),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _DateInfo(
                    label: l10n('Veriliş', 'Loaned'),
                    value: _formatDate(widget.loan.loanDate),
                  ),
                  _DateInfo(
                    label: l10n('Son tarih', 'Due date'),
                    value: _formatDate(widget.loan.dueDate),
                    color: isOverdue ? scheme.error : null,
                  ),
                  if (isReturned)
                    _DateInfo(
                      label: l10n('İade', 'Returned'),
                      value: _formatDate(widget.loan.returnedAt!),
                      color: scheme.tertiary,
                    ),
                  const SizedBox(width: 4),
                  if (widget.onEdit != null)
                    OutlinedButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: Text(l10n('Düzenle', 'Edit')),
                    ),
                  if (!isReturned && widget.onReturn != null)
                    FilledButton.tonalIcon(
                      onPressed: widget.onReturn,
                      icon: const Icon(Icons.assignment_return_rounded, size: 17),
                      label: Text(l10n('İade Al', 'Return')),
                    ),
                  if (!isReturned && widget.onEdit == null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LoanFormScreen(loan: widget.loan),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: Text(l10n('Düzenle', 'Edit')),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LoanMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DateInfo({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}

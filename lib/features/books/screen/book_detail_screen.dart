import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:libris/features/books/models/book_copy.dart';
import 'package:libris/features/books/screen/book_form_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  late Book _book;
  List<BookCopy> _copies = [];
  Map<String, int> _copyStats = const {
    'total': 0,
    'available': 0,
    'loaned': 0,
    'lost': 0,
    'maintenance': 0,
  };

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _refreshCopies();
  }

  Future<void> _refreshBook() async {
    final updated = await _databaseHelper.getBookById(_book.id!);
    if (!mounted || updated == null) return;
    setState(() => _book = updated);
  }

  Future<void> _refreshCopies() async {
    final copies = await _databaseHelper.getBookCopies(_book.id!);
    final stats = await _databaseHelper.getBookCopyStats(_book.id!);
    if (!mounted) return;
    setState(() {
      _copies = copies;
      _copyStats = stats;
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([_refreshBook(), _refreshCopies()]);
  }

  Future<void> _editBook() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookFormScreen(book: _book)),
    );
    await _refreshAll();
  }

  Future<void> _deleteBook() async {
    try {
      await _databaseHelper.deleteBook(_book.id!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _addCopy() async {
    final controller = TextEditingController();
    final code = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yeni Nüsha Ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Envanter / Barkod No',
            hintText: 'Boş bırakırsanız otomatik oluşturulur',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (code == null) return;
    try {
      await _databaseHelper.createBookCopy(
        _book.id!,
        inventoryCode: code.isEmpty ? null : code,
      );
      await _refreshAll();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _changeCopyStatus(
    BookCopy copy,
    BookCopyStatus status,
  ) async {
    try {
      await _databaseHelper.updateBookCopyStatus(copy.id!, status);
      await _refreshAll();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteCopy(BookCopy copy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nüshayı Sil'),
        content: Text(
          '${copy.inventoryCode} numaralı nüsha silinsin mi? Emanet geçmişi olan nüshalar silinemez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _databaseHelper.deleteBookCopy(copy.id!);
      await _refreshAll();
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Detayı'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editBook),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteBook),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _header(context),
            const SizedBox(height: 24),
            _infoTile('Yazar', _book.author),
            _infoTile('Açıklama', _book.description),
            _infoTile(
              'Durum',
              _book.isAvailable ? 'Müsait nüsha var' : 'Müsait nüsha yok',
              valueColor: _book.isAvailable ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fiziksel Nüshalar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _addCopy,
                  icon: const Icon(Icons.add),
                  label: const Text('Nüsha Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statChip('Toplam', _copyStats['total'] ?? 0),
                _statChip('Müsait', _copyStats['available'] ?? 0),
                _statChip('Emanette', _copyStats['loaned'] ?? 0),
                _statChip('Kayıp', _copyStats['lost'] ?? 0),
                _statChip('Bakımda', _copyStats['maintenance'] ?? 0),
              ],
            ),
            const SizedBox(height: 12),
            if (_copies.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Bu kitap için fiziksel nüsha kaydı bulunmuyor.'),
                ),
              )
            else
              ..._copies.map(_copyTile),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_book.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Chip(
          label: Text(_book.isAvailable ? 'Müsait' : 'Müsait Değil'),
          backgroundColor: _book.isAvailable
              ? Colors.green.shade100
              : Colors.red.shade100,
        ),
      ],
    );
  }

  Widget _copyTile(BookCopy copy) {
    final statusColor = _statusColor(copy.status);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(_statusIcon(copy.status), color: statusColor),
        ),
        title: Text(copy.inventoryCode),
        subtitle: Text(_statusLabel(copy.status)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<BookCopyStatus>(
              enabled: !copy.isLoaned,
              tooltip: copy.isLoaned
                  ? 'Emanetteki nüsha değiştirilemez'
                  : 'Durumu değiştir',
              onSelected: (status) => _changeCopyStatus(copy, status),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: BookCopyStatus.available,
                  child: Text('Müsait'),
                ),
                PopupMenuItem(
                  value: BookCopyStatus.lost,
                  child: Text('Kayıp'),
                ),
                PopupMenuItem(
                  value: BookCopyStatus.maintenance,
                  child: Text('Bakımda'),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Nüshayı sil',
              onPressed: copy.isLoaned ? null : () => _deleteCopy(copy),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, int value) {
    return Chip(label: Text('$label: $value'));
  }

  String _statusLabel(BookCopyStatus status) {
    return switch (status) {
      BookCopyStatus.available => 'Müsait',
      BookCopyStatus.loaned => 'Emanette',
      BookCopyStatus.lost => 'Kayıp',
      BookCopyStatus.maintenance => 'Bakımda',
    };
  }

  IconData _statusIcon(BookCopyStatus status) {
    return switch (status) {
      BookCopyStatus.available => Icons.check_circle,
      BookCopyStatus.loaned => Icons.schedule,
      BookCopyStatus.lost => Icons.help_outline,
      BookCopyStatus.maintenance => Icons.build_outlined,
    };
  }

  Color _statusColor(BookCopyStatus status) {
    return switch (status) {
      BookCopyStatus.available => Colors.green,
      BookCopyStatus.loaned => Colors.orange,
      BookCopyStatus.lost => Colors.red,
      BookCopyStatus.maintenance => Colors.blueGrey,
    };
  }

  Widget _infoTile(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, color: valueColor)),
        ],
      ),
    );
  }
}

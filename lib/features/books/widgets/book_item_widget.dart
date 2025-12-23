import 'package:flutter/material.dart';
import 'package:libris/features/books/models/book.dart';

enum BookViewType { card, list }

class BookItemWidget extends StatelessWidget {
  final Book book;
  final BookViewType viewType;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BookItemWidget({
    super.key,
    required this.book,
    this.viewType = BookViewType.list,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return viewType == BookViewType.card
        ? _buildCard(context)
        : _buildListTile(context);
  }

  Widget _buildListTile(BuildContext context) {
    return ListTile(
      title: Text(book.title),
      subtitle: Text(book.author),
      leading: Icon(
        book.isAvailable ? Icons.book : Icons.book_outlined,
        color: book.isAvailable ? Colors.green : Colors.red,
      ),
      trailing: _buildActions(),
      onTap: onTap,
    );
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(book.author, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_availabilityChip(), _buildActions()],
            ),
          ],
        ),
      ),
    );
  }

  Widget _availabilityChip() {
    return Chip(
      label: Text(book.isAvailable ? 'Müsait' : 'Emanette'),
      backgroundColor: book.isAvailable
          ? Colors.green.shade100
          : Colors.red.shade100,
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
        if (onDelete != null)
          IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
      ],
    );
  }
}

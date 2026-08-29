import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final statusColor = book.isAvailable ? scheme.tertiary : scheme.error;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            book.isAvailable ? Icons.menu_book_rounded : Icons.book_outlined,
            color: statusColor,
            size: 21,
          ),
        ),
        title: Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if ((book.category ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    book.category!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _availabilityBadge(context),
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(width: 4),
              _actionsMenu(),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = book.isAvailable ? scheme.tertiary : scheme.error;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: statusColor,
                      size: 21,
                    ),
                  ),
                  const Spacer(),
                  if (onEdit != null || onDelete != null) _actionsMenu(),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              if ((book.category ?? '').isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        book.category!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              if ((book.location ?? '').isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.shelves,
                      size: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        book.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _availabilityBadge(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _availabilityBadge(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = book.isAvailable ? scheme.tertiary : scheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        book.isAvailable ? l10n('Müsait', 'Available') : l10n('Emanette', 'On loan'),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _actionsMenu() {
    return PopupMenuButton<String>(
      tooltip: l10n('İşlemler', 'Actions'),
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n('Düzenle', 'Edit')),
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(l10n('Sil', 'Delete')),
            ),
          ),
      ],
    );
  }
}

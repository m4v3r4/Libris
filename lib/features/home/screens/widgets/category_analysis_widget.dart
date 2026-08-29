import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/providers/database_provider.dart';
import 'package:libris/features/home/screens/widgets/dashboard_card.dart';
import 'package:provider/provider.dart';

class CategoryAnalysisWidget extends StatefulWidget {
  const CategoryAnalysisWidget({super.key});

  @override
  State<CategoryAnalysisWidget> createState() => _CategoryAnalysisWidgetState();
}

class _CategoryAnalysisWidgetState extends State<CategoryAnalysisWidget> {
  DatabaseProvider? _provider;
  late Future<List<Map<String, dynamic>>> _statsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<DatabaseProvider>();

    if (!identical(_provider, nextProvider)) {
      _provider?.removeListener(_onDatabaseChanged);
      _provider = nextProvider;
      _provider!.addListener(_onDatabaseChanged);
      _reload();
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  void _onDatabaseChanged() {
    _reload();
  }

  void _reload() {
    final provider = _provider;
    if (provider == null) return;

    setState(() {
      _statsFuture = provider.getCategoriesWithStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: l10n('Kategoriler', 'Categories'),
      subtitle: l10n('Koleksiyon dağılımı', 'Collection distribution'),
      icon: Icons.category_rounded,
      trailing: IconButton(
        onPressed: _reload,
        icon: const Icon(Icons.refresh_rounded),
        tooltip: l10n('Yenile', 'Refresh'),
      ),
      bodyPadding: const EdgeInsets.all(16),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ?? const <Map<String, dynamic>>[];
          if (stats.isEmpty) {
            return DashboardEmptyState(
              icon: Icons.category_outlined,
              title: l10n('Kategori verisi yok', 'No category data'),
              description: l10n(
                'Kategoriler ve kitaplar eklendikçe dağılım burada oluşacak.',
                'The distribution will appear here as categories and books are added.',
              ),
            );
          }

          var totalBooks = 0;
          var maxBooks = 0;
          var mostPopular = '-';

          for (final item in stats) {
            final count = item['book_count'] as int;
            totalBooks += count;
            if (count > maxBooks) {
              maxBooks = count;
              mostPopular = item['name'] as String;
            }
          }

          final scheme = Theme.of(context).colorScheme;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    label: l10n('Kategori', 'Categories'),
                    value: '${stats.length}',
                  ),
                  _StatChip(
                    label: l10n('Toplam', 'Total'),
                    value: l10n('$totalBooks kitap', '$totalBooks books'),
                  ),
                  _StatChip(
                    label: l10n('En Popüler', 'Most Popular'),
                    value: mostPopular.length > 16
                        ? '${mostPopular.substring(0, 16)}...'
                        : mostPopular,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: stats.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = stats[index];
                    final count = item['book_count'] as int;
                    final name = item['name'] as String;
                    final percentage = totalBooks > 0 ? count / totalBooks : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$count · ${(percentage * 100).toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        LinearProgressIndicator(
                          value: percentage,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: scheme.primary,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:libris/common/providers/database_provider.dart';
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = snapshot.data ?? const <Map<String, dynamic>>[];
            if (stats.isEmpty) {
              return const Center(child: Text('Kategori verisi bulunamadi.'));
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kategori Analizi',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Yenile',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatChip(label: 'Kategori', value: '${stats.length}'),
                    _StatChip(label: 'Toplam', value: '$totalBooks kitap'),
                    _StatChip(
                      label: 'En Populer',
                      value: mostPopular.length > 16
                          ? '${mostPopular.substring(0, 16)}...'
                          : mostPopular,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: stats.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
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
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('$count (%${(percentage * 100).toStringAsFixed(1)})'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(5),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: scheme.primaryContainer.withValues(alpha: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';

class CategoryAnalysisWidget extends StatelessWidget {
  final List<Map<String, dynamic>> categoryStats;

  const CategoryAnalysisWidget({super.key, required this.categoryStats});

  @override
  Widget build(BuildContext context) {
    int totalBooks = 0;
    int totalCategories = categoryStats.length;
    String mostPopular = '-';
    int maxBooks = 0;

    for (var item in categoryStats) {
      int count = item['book_count'] as int;
      totalBooks += count;
      if (count > maxBooks) {
        maxBooks = count;
        mostPopular = item['name'] as String;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kategori Analizi', style: TextStyle(fontSize: 18)),

            // Özet Kartı
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const SizedBox(width: 16),
                    _buildStatItem('Kategori', '$totalCategories'),
                    _buildStatItem('Toplam Kitap', '$totalBooks'),
                    _buildStatItem(
                      'En Popüler',
                      mostPopular.length > 10
                          ? '${mostPopular.substring(0, 8)}...'
                          : mostPopular,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Kategori Dağılımı', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            // Liste ve Grafikler
            ...categoryStats.map((item) {
              final count = item['book_count'] as int;
              final name = item['name'] as String;
              final double percentage = totalBooks > 0 ? count / totalBooks : 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$count kitap (%${(percentage * 100).toStringAsFixed(1)})',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: Colors.grey[200],
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

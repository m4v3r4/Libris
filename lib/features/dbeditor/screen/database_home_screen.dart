import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libris/features/dbeditor/services/database_inspector_service.dart';
import 'package:libris/features/dbeditor/widgets/table_view.dart';
import 'package:libris/features/settings/screen/category_manager_screen.dart';

class DatabaseHomeScreen extends StatefulWidget {
  const DatabaseHomeScreen({super.key});

  @override
  State<DatabaseHomeScreen> createState() => _DatabaseHomeScreenState();
}

class _DatabaseHomeScreenState extends State<DatabaseHomeScreen> {
  final DatabaseInspectorService _service = DatabaseInspectorService();
  List<String> _tables = [];
  String? _selectedTable;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    final tables = await _service.getTables();
    if (!mounted) return;
    setState(() {
      _tables = tables;
      _isLoading = false;
    });
  }

  Future<void> _exportDatabase() async {
    setState(() => _isLoading = true);
    try {
      final tables = await _service.getTables();
      final Map<String, dynamic> dbExport = {};

      for (final table in tables) {
        final rows = await _service.getTableData(table);
        dbExport[table] = rows;
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(dbExport);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Veritabanı Dışa Aktar'),
          content: SingleChildScrollView(child: SelectableText(jsonString)),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonString));
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Kopyalandı!')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Kopyala'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _importDatabase() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Veritabanı İçe Aktar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('JSON verisini buraya yapıştırın:'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"tablo_adi": [...]}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _processImport(controller.text);
            },
            child: const Text('İçe Aktar'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _processImport(String jsonString) async {
    if (jsonString.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Geçersiz JSON formatı.');
      }
      final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
      int totalRows = 0;

      for (final table in data.keys) {
        final rows = data[table];
        if (rows is List) {
          for (final row in rows) {
            if (row is Map<String, dynamic>) {
              await _service.insertRow(table, row);
              totalRows++;
            }
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İçe aktarma başarılı: $totalRows kayıt.')),
      );
      _loadTables();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('İçe aktarma hatası: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openCategoryManager() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryManagerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veritabanı Yöneticisi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'İçe Aktar',
            onPressed: _importDatabase,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Dışa Aktar',
            onPressed: _exportDatabase,
          ),
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Kategorileri Yönet',
            onPressed: _openCategoryManager,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    child: const Text(
                      'Tablolar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            itemCount: _tables.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final table = _tables[index];
                              final isSelected = table == _selectedTable;
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                leading: const Icon(
                                  Icons.table_chart,
                                  color: Colors.blue,
                                ),
                                title: Text(table),
                                trailing: isSelected
                                    ? const Icon(Icons.chevron_right)
                                    : null,
                                onTap: () {
                                  setState(() => _selectedTable = table);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 9,
            child: _selectedTable == null
                ? const Center(child: Text('İşlem yapmak için bir tablo seçin'))
                : TableViewScreen(
                    key: ValueKey(_selectedTable),
                    tableName: _selectedTable!,
                  ),
          ),
        ],
      ),
    );
  }
}

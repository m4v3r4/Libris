import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libris/common/database/database_backup_service.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/widgets/section_toolbar.dart';
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
  final DatabaseBackupService _backupService = const DatabaseBackupService();
  final TextEditingController _searchController = TextEditingController();

  List<String> _tables = [];
  String? _selectedTable;
  String _query = '';
  bool _isLoading = true;

  List<String> get _filteredTables {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _tables;
    return _tables
        .where((table) => table.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);

    try {
      final tables = await _service.getTables();
      if (!mounted) return;
      setState(() {
        _tables = tables;
        if (_selectedTable == null || !tables.contains(_selectedTable)) {
          _selectedTable = tables.isEmpty ? null : tables.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n('Tablolar yüklenemedi: $e', 'Tables could not be loaded: $e'),
          ),
        ),
      );
    }
  }

  Future<void> _exportDatabase() async {
    setState(() => _isLoading = true);
    try {
      final db = await _service.getDatabase();
      final backup = await _backupService.createBackup(db);
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.download_rounded),
              const SizedBox(width: 10),
              Text(l10n('Veritabanını Dışa Aktar', 'Export Database')),
            ],
          ),
          content: SizedBox(
            width: 720,
            height: 480,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(
                  dialogContext,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonString,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n('Kapat', 'Close')),
            ),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonString));
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n(
                        'JSON panoya kopyalandı.',
                        'JSON copied to clipboard.',
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(l10n('Kopyala', 'Copy')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n('Dışa aktarma başarısız: $e', 'Export failed: $e'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importDatabase() async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.upload_rounded),
            const SizedBox(width: 10),
            Text(l10n('Veritabanına İçe Aktar', 'Import Database')),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n(
                  'Libris tarafından oluşturulmuş sürümlü JSON yedeğini aşağıya yapıştırın. Geri yükleme tek işlem olarak uygulanır; hata olursa mevcut veritabanı değişmeden kalır.',
                  'Paste a versioned JSON backup created by Libris. Restore runs atomically; if it fails, the existing database remains unchanged.',
                ),
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                minLines: 8,
                maxLines: 14,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '{"table_name": [...]}',
                  alignLabelWithHint: true,
                  labelText: l10n('JSON verisi', 'JSON data'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n('Vazgeç', 'Cancel')),
          ),
          FilledButton.icon(
            onPressed: () {
              final json = controller.text.trim();
              Navigator.pop(dialogContext);
              _processImport(json);
            },
            icon: const Icon(Icons.upload_rounded, size: 18),
            label: Text(l10n('İçe Aktar', 'Import')),
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
        throw const DatabaseBackupException('Geçersiz JSON formatı.');
      }

      final db = await _service.getDatabase();
      await _backupService.restoreBackup(db, decoded);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n(
              'Yedek başarıyla geri yüklendi.',
              'Backup restored successfully.',
            ),
          ),
        ),
      );
      await _loadTables();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n('İçe aktarma hatası: $e', 'Import error: $e')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          SectionToolbar(
            title: l10n('Veritabanı Yöneticisi', 'Database Manager'),
            subtitle: l10n(
              'Yerel SQLite tablolarını inceleyin ve bakım işlemlerini yönetin.',
              'Inspect local SQLite tables and manage maintenance operations.',
            ),
            icon: Icons.storage_rounded,
            count: _tables.length,
            onClose: () => Navigator.maybePop(context),
            leadingIcon: Icons.arrow_back_rounded,
            leadingTooltip: l10n('Geri', 'Back'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n('Yenile', 'Refresh'),
                onPressed: _isLoading ? null : _loadTables,
              ),
              IconButton(
                icon: const Icon(Icons.category_outlined),
                tooltip: l10n('Kategorileri Yönet', 'Manage Categories'),
                onPressed: _openCategoryManager,
              ),
              const SizedBox(width: 4),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _importDatabase,
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: Text(l10n('İçe Aktar', 'Import')),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isLoading ? null : _exportDatabase,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(l10n('Dışa Aktar', 'Export')),
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 820) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedTable,
                          decoration: InputDecoration(
                            labelText: l10n('Tablo', 'Table'),
                            prefixIcon: const Icon(Icons.table_chart_outlined),
                          ),
                          items: _tables
                              .map(
                                (table) => DropdownMenuItem(
                                  value: table,
                                  child: Text(table),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedTable = value);
                          },
                        ),
                      ),
                      Divider(height: 1, color: scheme.outlineVariant),
                      Expanded(child: _buildTableContent()),
                    ],
                  );
                }

                return Row(
                  children: [
                    SizedBox(
                      width: 270,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          border: Border(
                            right: BorderSide(color: scheme.outlineVariant),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                14,
                                14,
                                10,
                              ),
                              child: SectionSearchField(
                                controller: _searchController,
                                hintText: l10n(
                                  'Tablo ara...',
                                  'Search tables...',
                                ),
                                onChanged: (value) {
                                  setState(() => _query = value);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                              child: Text(
                                l10n('TABLOLAR', 'TABLES'),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                            ),
                            Expanded(child: _buildTableList()),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: _buildTableContent()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableList() {
    final tables = _filteredTables;
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tables.isEmpty) {
      return SectionEmptyState(
        icon: Icons.table_chart_outlined,
        title: l10n('Tablo bulunamadı', 'No tables found'),
        description: l10n(
          'Yerel veritabanında görüntülenecek tablo yok.',
          'There are no tables to display in the local database.',
        ),
      );
    }

    if (tables.isEmpty) {
      return SectionEmptyState(
        icon: Icons.search_off_rounded,
        title: l10n('Tablo bulunamadı', 'No tables found'),
        description: l10n(
          'Arama ifadenizi değiştirerek tekrar deneyin.',
          'Try changing your search query.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final selected = table == _selectedTable;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            selected: selected,
            selectedColor: scheme.primary,
            selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            leading: Icon(
              Icons.table_chart_outlined,
              size: 20,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            title: Text(
              table,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            trailing: selected
                ? Icon(Icons.chevron_right_rounded, color: scheme.primary)
                : null,
            onTap: () => setState(() => _selectedTable = table),
          ),
        );
      },
    );
  }

  Widget _buildTableContent() {
    if (_isLoading && _selectedTable == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final selected = _selectedTable;
    if (selected == null) {
      return SectionEmptyState(
        icon: Icons.table_rows_outlined,
        title: l10n('Bir tablo seçin', 'Select a table'),
        description: l10n(
          'Kayıtları görüntülemek ve düzenlemek için soldaki listeden bir tablo seçin.',
          'Select a table from the list to view and edit its records.',
        ),
      );
    }

    return TableViewScreen(key: ValueKey(selected), tableName: selected);
  }
}

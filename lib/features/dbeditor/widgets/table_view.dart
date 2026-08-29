import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/widgets/section_toolbar.dart';
import 'package:libris/features/dbeditor/services/database_inspector_service.dart';
import 'package:path_provider/path_provider.dart';

class TableViewScreen extends StatefulWidget {
  final String tableName;

  const TableViewScreen({super.key, required this.tableName});

  @override
  State<TableViewScreen> createState() => _TableViewScreenState();
}

class _TableViewScreenState extends State<TableViewScreen> {
  final DatabaseInspectorService _service = DatabaseInspectorService();

  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _schema = [];
  String? _pk;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final schema = await _service.getTableSchema(widget.tableName);
      final data = await _service.getTableData(widget.tableName);

      String? pk;
      for (final column in schema) {
        if (column['pk'] == 1) {
          pk = column['name'] as String?;
          break;
        }
      }
      pk ??= schema.isNotEmpty ? schema.first['name'] as String? : null;

      if (!mounted) return;
      setState(() {
        _schema = schema;
        _data = data;
        _pk = pk;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n('Tablo yüklenemedi: $e', 'Table could not be loaded: $e'),
          ),
        ),
      );
    }
  }

  Future<void> _addRow() async {
    final values = await _editDialog({});
    if (values != null) {
      await _service.insertRow(widget.tableName, values);
      await _load();
    }
  }

  Future<void> _editRow(Map<String, dynamic> row) async {
    final values = await _editDialog(row);
    if (values != null && _pk != null) {
      await _service.updateRow(widget.tableName, _pk!, row[_pk], values);
      await _load();
    }
  }

  Future<void> _deleteRow(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded),
            const SizedBox(width: 10),
            Text(l10n('Kaydı sil?', 'Delete record?')),
          ],
        ),
        content: Text(
          l10n(
            'Bu kayıt kalıcı olarak silinecek. Bu işlem geri alınamaz.',
            'This record will be permanently deleted. This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n('Vazgeç', 'Cancel')),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(l10n('Sil', 'Delete')),
          ),
        ],
      ),
    );

    if (ok == true && _pk != null) {
      await _service.deleteRow(widget.tableName, _pk!, row[_pk]);
      await _load();
    }
  }

  Future<void> _exportJson() async {
    final file = await _pickSaveFile('json');
    if (file == null) return;

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_data));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n('JSON kaydedildi: ${file.path}', 'JSON saved: ${file.path}'),
        ),
      ),
    );
  }

  Future<void> _importJson() async {
    final file = await _pickOpenFile();
    if (file == null) return;

    final dynamic decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n(
              'JSON verisi bir liste olmalıdır.',
              'JSON data must be a list.',
            ),
          ),
        ),
      );
      return;
    }
    await _transactionImport(decoded);
  }

  Future<void> _exportCsv() async {
    final rows = [
      _schema.map((column) => column['name']).toList(),
      ..._data.map(
        (row) => _schema.map((column) => row[column['name']]).toList(),
      ),
    ];
    final csv = const ListToCsvConverter().convert(rows);

    final file = await _pickSaveFile('csv');
    if (file == null) return;
    await file.writeAsString(csv);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n('CSV kaydedildi: ${file.path}', 'CSV saved: ${file.path}'),
        ),
      ),
    );
  }

  Future<void> _importCsv() async {
    final file = await _pickOpenFile();
    if (file == null) return;

    final csv = const CsvToListConverter().convert(await file.readAsString());
    if (csv.isEmpty) return;

    final headers = csv.first.map((value) => value.toString()).toList();
    final rows = csv.skip(1).map((values) {
      final row = <String, dynamic>{};
      for (var i = 0; i < headers.length; i++) {
        row[headers[i]] = i < values.length ? values[i] : null;
      }
      return row;
    }).toList();

    await _transactionImport(rows);
  }

  Future<void> _exportExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow(
      _schema
          .map((column) => TextCellValue(column['name'].toString()))
          .toList(),
    );
    for (final row in _data) {
      sheet.appendRow(
        _schema
            .map(
              (column) => TextCellValue(
                row[column['name']]?.toString() ?? '',
              ),
            )
            .toList(),
      );
    }

    final file = await _pickSaveFile('xlsx');
    if (file == null) return;
    final bytes = excel.encode();
    if (bytes == null) return;
    await file.writeAsBytes(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n('Excel kaydedildi: ${file.path}', 'Excel saved: ${file.path}'),
        ),
      ),
    );
  }

  Future<void> _importExcel() async {
    final file = await _pickOpenFile();
    if (file == null) return;

    final excel = Excel.decodeBytes(await file.readAsBytes());
    if (excel.tables.isEmpty) return;

    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) return;

    final headers = sheet.rows.first
        .map((cell) => cell?.value?.toString() ?? '')
        .toList();
    final rows = sheet.rows.skip(1).map((values) {
      final row = <String, dynamic>{};
      for (var i = 0; i < headers.length; i++) {
        row[headers[i]] = i < values.length ? values[i]?.value : null;
      }
      return row;
    }).toList();

    await _transactionImport(rows);
  }

  Future<void> _transactionImport(List rows) async {
    var count = 0;
    for (final row in rows) {
      if (row is Map<String, dynamic>) {
        await _service.insertRow(widget.tableName, row);
        count++;
      }
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n('$count kayıt içe aktarıldı.', '$count records imported.'),
        ),
      ),
    );
  }

  Future<File?> _pickSaveFile(String extension) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${widget.tableName}.$extension');
  }

  Future<File?> _pickOpenFile() async {
    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    return path == null ? null : File(path);
  }

  Future<Map<String, dynamic>?> _editDialog(Map<String, dynamic> row) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _EditDialog(
        schema: _schema,
        row: row,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.table_chart_outlined,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tableName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      l10n(
                        '${_data.length} kayıt · ${_schema.length} sütun',
                        '${_data.length} records · ${_schema.length} columns',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n('Tabloyu yenile', 'Refresh table'),
              ),
              _buildImportExportMenu(),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n('Kayıt Ekle', 'Add Record')),
              ),
            ],
          ),
        ),
        Expanded(
          child: _data.isEmpty
              ? SectionEmptyState(
                  icon: Icons.table_rows_outlined,
                  title: l10n('Bu tabloda kayıt yok', 'No records in this table'),
                  description: l10n(
                    'Yeni bir kayıt ekleyebilir veya dosyadan veri içe aktarabilirsiniz.',
                    'Add a new record or import data from a file.',
                  ),
                  actionLabel: l10n('Kayıt Ekle', 'Add Record'),
                  onAction: _addRow,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth - 28,
                          ),
                          child: PaginatedDataTable(
                            header: null,
                            showFirstLastButtons: true,
                            columns: [
                              ..._schema.map(
                                (column) => DataColumn(
                                  label: Text(
                                    column['name'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(label: Text(l10n('İşlemler', 'Actions'))),
                            ],
                            source: _TableSource(
                              _data,
                              _schema,
                              _editRow,
                              _deleteRow,
                            ),
                            rowsPerPage: 20,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  PopupMenuButton<String> _buildImportExportMenu() {
    return PopupMenuButton<String>(
      tooltip: l10n('İçe / dışa aktar', 'Import / export'),
      icon: const Icon(Icons.import_export_rounded),
      onSelected: (value) {
        switch (value) {
          case 'json_in':
            _importJson();
            break;
          case 'json_out':
            _exportJson();
            break;
          case 'csv_in':
            _importCsv();
            break;
          case 'csv_out':
            _exportCsv();
            break;
          case 'xls_in':
            _importExcel();
            break;
          case 'xls_out':
            _exportExcel();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            l10n('İçe Aktar', 'Import'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        PopupMenuItem(value: 'json_in', child: Text(l10n('JSON içe aktar', 'Import JSON'))),
        PopupMenuItem(value: 'csv_in', child: Text(l10n('CSV içe aktar', 'Import CSV'))),
        PopupMenuItem(value: 'xls_in', child: Text(l10n('Excel içe aktar', 'Import Excel'))),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: false,
          child: Text(
            l10n('Dışa Aktar', 'Export'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        PopupMenuItem(value: 'json_out', child: Text(l10n('JSON dışa aktar', 'Export JSON'))),
        PopupMenuItem(value: 'csv_out', child: Text(l10n('CSV dışa aktar', 'Export CSV'))),
        PopupMenuItem(value: 'xls_out', child: Text(l10n('Excel dışa aktar', 'Export Excel'))),
      ],
    );
  }
}

class _TableSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> schema;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

  _TableSource(this.data, this.schema, this.onEdit, this.onDelete);

  @override
  DataRow getRow(int index) {
    final row = data[index];
    return DataRow(
      cells: [
        ...schema.map(
          (column) => DataCell(
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                '${row[column['name']] ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n('Düzenle', 'Edit'),
                onPressed: () => onEdit(row),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: l10n('Sil', 'Delete'),
                onPressed: () => onDelete(row),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  int get rowCount => data.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

class _EditDialog extends StatefulWidget {
  final List<Map<String, dynamic>> schema;
  final Map<String, dynamic> row;

  const _EditDialog({required this.schema, required this.row});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  final Map<String, TextEditingController> controllers = {};

  bool get _isEditing => widget.row.isNotEmpty;

  @override
  void initState() {
    super.initState();
    for (final column in widget.schema) {
      final name = column['name'] as String;
      controllers[name] = TextEditingController(
        text: widget.row[name]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editableColumns = widget.schema.where((column) => column['pk'] != 1);

    return AlertDialog(
      title: Row(
        children: [
          Icon(_isEditing ? Icons.edit_outlined : Icons.add_rounded),
          const SizedBox(width: 10),
          Text(
            _isEditing
                ? l10n('Kaydı Düzenle', 'Edit Record')
                : l10n('Yeni Kayıt', 'New Record'),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            children: editableColumns.map((column) {
              final name = column['name'] as String;
              final type = column['type']?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[name],
                  decoration: InputDecoration(
                    labelText: name,
                    helperText: type.isEmpty ? null : type,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n('Vazgeç', 'Cancel')),
        ),
        FilledButton.icon(
          onPressed: () {
            final values = <String, dynamic>{};
            for (final column in widget.schema) {
              if (column['pk'] == 1) continue;
              final name = column['name'] as String;
              values[name] = controllers[name]?.text ?? '';
            }
            Navigator.pop(context, values);
          },
          icon: const Icon(Icons.save_outlined, size: 18),
          label: Text(
            _isEditing ? l10n('Kaydet', 'Save') : l10n('Ekle', 'Add'),
          ),
        ),
      ],
    );
  }
}

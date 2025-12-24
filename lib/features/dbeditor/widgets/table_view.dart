import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
    final schema = await _service.getTableSchema(widget.tableName);
    final data = await _service.getTableData(widget.tableName);

    String? pk;
    for (final c in schema) {
      if (c['pk'] == 1) {
        pk = c['name'];
        break;
      }
    }
    pk ??= schema.isNotEmpty ? schema.first['name'] : null;

    setState(() {
      _schema = schema;
      _data = data;
      _pk = pk;
      _loading = false;
    });
  }

  // ---------------- CRUD ----------------

  Future<void> _addRow() async {
    final values = await _editDialog({});
    if (values != null) {
      await _service.insertRow(widget.tableName, values);
      _load();
    }
  }

  Future<void> _editRow(Map<String, dynamic> row) async {
    final values = await _editDialog(row);
    if (values != null && _pk != null) {
      await _service.updateRow(widget.tableName, _pk!, row[_pk], values);
      _load();
    }
  }

  Future<void> _deleteRow(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sil'),
        content: const Text('Bu kayıt kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok == true && _pk != null) {
      await _service.deleteRow(widget.tableName, _pk!, row[_pk]);
      _load();
    }
  }

  // ---------------- JSON ----------------

  Future<void> _exportJson() async {
    final file = await _pickSaveFile('json');
    if (file == null) return;

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_data));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('JSON kaydedildi: ${file.path}')));
    }
  }

  Future<void> _importJson() async {
    final file = await _pickOpenFile();
    if (file == null) return;

    final dynamic decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hata: JSON verisi bir liste olmalıdır.'),
          ),
        );
      }
      return;
    }
    await _transactionImport(decoded);
  }

  // ---------------- CSV ----------------

  Future<void> _exportCsv() async {
    final rows = [
      _schema.map((c) => c['name']).toList(),
      ..._data.map((r) => _schema.map((c) => r[c['name']]).toList()),
    ];
    final csv = const ListToCsvConverter().convert(rows);

    final file = await _pickSaveFile('csv');
    if (file != null) {
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV kaydedildi: ${file.path}')));
      }
    }
  }

  Future<void> _importCsv() async {
    final file = await _pickOpenFile();
    if (file == null) return;

    final csv = const CsvToListConverter().convert(await file.readAsString());
    if (csv.isEmpty) return;

    final headers = csv.first.map((e) => e.toString()).toList();
    final rows = csv.skip(1).map((r) {
      final rowMap = <String, dynamic>{};
      for (int i = 0; i < headers.length; i++) {
        rowMap[headers[i]] = (i < r.length) ? r[i] : null;
      }
      return rowMap;
    }).toList();

    await _transactionImport(rows);
  }

  // ---------------- EXCEL ----------------

  Future<void> _exportExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow(
      _schema.map((c) => TextCellValue(c['name'].toString())).toList(),
    );
    for (final row in _data) {
      sheet.appendRow(
        _schema
            .map((c) => TextCellValue(row[c['name']]?.toString() ?? ''))
            .toList(),
      );
    }

    final file = await _pickSaveFile('xlsx');
    if (file != null) {
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Excel kaydedildi: ${file.path}')),
          );
        }
      }
    }
  }

  Future<void> _importExcel() async {
    final file = await _pickOpenFile();
    if (file == null) return;

    final excel = Excel.decodeBytes(await file.readAsBytes());
    if (excel.tables.isEmpty) return;

    final sheet = excel.tables.values.first;
    if (sheet == null || sheet.rows.isEmpty) return;

    final headers = sheet.rows.first
        .map((e) => e?.value?.toString() ?? '')
        .toList();
    final rows = sheet.rows.skip(1).map((r) {
      final rowMap = <String, dynamic>{};
      for (int i = 0; i < headers.length; i++) {
        rowMap[headers[i]] = (i < r.length) ? r[i]?.value : null;
      }
      return rowMap;
    }).toList();

    await _transactionImport(rows);
  }

  // ---------------- Helpers ----------------

  Future<void> _transactionImport(List rows) async {
    int count = 0;
    for (final r in rows) {
      if (r is Map<String, dynamic>) {
        await _service.insertRow(widget.tableName, r);
        count++;
      }
    }
    _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$count kayıt içe aktarıldı')));
    }
  }

  Future<File?> _pickSaveFile(String ext) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${widget.tableName}.$ext');
  }

  Future<File?> _pickOpenFile() async {
    final res = await FilePicker.platform.pickFiles();
    if (res == null) return null;
    return File(res.files.single.path!);
  }

  Future<Map<String, dynamic>?> _editDialog(Map<String, dynamic> row) {
    return showDialog(
      context: context,
      builder: (_) => _EditDialog(schema: _schema, row: row),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.tableName),
          actions: [
            IconButton(icon: const Icon(Icons.add), onPressed: _addRow),
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
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
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'json_in', child: Text('JSON Import')),
                PopupMenuItem(value: 'json_out', child: Text('JSON Export')),
                PopupMenuItem(value: 'csv_in', child: Text('CSV Import')),
                PopupMenuItem(value: 'csv_out', child: Text('CSV Export')),
                PopupMenuItem(value: 'xls_in', child: Text('Excel Import')),
                PopupMenuItem(value: 'xls_out', child: Text('Excel Export')),
              ],
            ),
          ],
        ),
        body: const Center(child: Text('Tabloda veri yok.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tableName),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addRow),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
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
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'json_in', child: Text('JSON Import')),
              PopupMenuItem(value: 'json_out', child: Text('JSON Export')),
              PopupMenuItem(value: 'csv_in', child: Text('CSV Import')),
              PopupMenuItem(value: 'csv_out', child: Text('CSV Export')),
              PopupMenuItem(value: 'xls_in', child: Text('Excel Import')),
              PopupMenuItem(value: 'xls_out', child: Text('Excel Export')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: PaginatedDataTable(
          columns: [
            ..._schema.map((c) => DataColumn(label: Text(c['name']))),
            const DataColumn(label: Text('')),
          ],
          source: _TableSource(_data, _schema, _editRow, _deleteRow),
          rowsPerPage: 20,
        ),
      ),
    );
  }
}

// ---------------- DataSource ----------------

class _TableSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final List schema;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;

  _TableSource(this.data, this.schema, this.onEdit, this.onDelete);

  @override
  DataRow getRow(int index) {
    final row = data[index];
    return DataRow(
      cells: [
        ...schema.map((c) => DataCell(Text('${row[c['name']] ?? ''}'))),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => onEdit(row),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
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

// ---------------- Edit Dialog ----------------

class _EditDialog extends StatefulWidget {
  final List schema;
  final Map<String, dynamic> row;
  const _EditDialog({required this.schema, required this.row});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  final Map<String, TextEditingController> c = {};

  @override
  void initState() {
    super.initState();
    for (final col in widget.schema) {
      c[col['name']] = TextEditingController(
        text: widget.row[col['name']]?.toString() ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kayıt'),
      content: SingleChildScrollView(
        child: Column(
          children: widget.schema.where((c) => c['pk'] != 1).map((col) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: c[col['name']],
                decoration: InputDecoration(
                  labelText: col['name'],
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            final m = <String, dynamic>{};
            c.forEach((k, v) => m[k] = v.text);
            Navigator.pop(context, m);
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

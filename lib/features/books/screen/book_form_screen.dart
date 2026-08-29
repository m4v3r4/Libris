import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';

class BookFormScreen extends StatefulWidget {
  final Book? book;

  const BookFormScreen({super.key, this.book});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookService = DatabaseHelper.instance;

  late final bool _isEditing;
  late final bool _isAvailable;
  bool _isSaving = false;

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _isbnController = TextEditingController();
  final _publisherController = TextEditingController();
  final _publishYearController = TextEditingController();
  final _pageCountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.book != null;

    if (_isEditing) {
      final book = widget.book!;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _descriptionController.text = book.description;
      _isbnController.text = book.isbn ?? '';
      _publisherController.text = book.publisher ?? '';
      _publishYearController.text = book.publishYear?.toString() ?? '';
      _pageCountController.text = book.pageCount?.toString() ?? '';
      _categoryController.text = book.category ?? '';
      _locationController.text = book.location ?? '';
      _isAvailable = book.isAvailable;
    } else {
      _isAvailable = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _publishYearController.dispose();
    _pageCountController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final book = Book(
        id: _isEditing ? widget.book!.id : null,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        isbn: _nullableText(_isbnController),
        publisher: _nullableText(_publisherController),
        publishYear: _nullableInt(_publishYearController),
        pageCount: _nullableInt(_pageCountController),
        category: _nullableText(_categoryController),
        location: _nullableText(_locationController),
        isAvailable: _isAvailable,
      );

      if (_isEditing) {
        await _bookService.updateBook(book);
      } else {
        await _bookService.createBook(book);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  int? _nullableInt(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : int.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n('Kitabı Düzenle', 'Edit Book') : l10n('Yeni Kitap', 'New Book'),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormIntro(
                    icon: Icons.menu_book_rounded,
                    title: _isEditing
                        ? l10n('Kitap bilgilerini güncelleyin', 'Update book information')
                        : l10n('Kataloğa yeni bir kitap ekleyin', 'Add a new book to the catalog'),
                    description: _isEditing
                        ? l10n(
                            'Bibliyografik bilgiler ve kütüphane konumu burada düzenlenir.',
                            'Edit bibliographic details and library location here.',
                          )
                        : l10n(
                            'Temel bilgileri girin. Fiziksel nüshalar kitap oluşturulduktan sonra yönetilebilir.',
                            'Enter the basic information. Physical copies can be managed after the book is created.',
                          ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 760;
                      final fieldWidth = twoColumns
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            child: _FormSection(
                              title: l10n('Temel Bilgiler', 'Basic Information'),
                              icon: Icons.subject_rounded,
                              children: [
                                _textField(
                                  _titleController,
                                  l10n('Kitap adı', 'Book title'),
                                  icon: Icons.title_rounded,
                                  required: true,
                                  autofocus: !_isEditing,
                                ),
                                _textField(
                                  _authorController,
                                  l10n('Yazar', 'Author'),
                                  icon: Icons.person_outline_rounded,
                                  required: true,
                                ),
                                _textField(
                                  _descriptionController,
                                  l10n('Açıklama', 'Description'),
                                  icon: Icons.notes_rounded,
                                  maxLines: 5,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _FormSection(
                              title: l10n('Yayın Bilgileri', 'Publication Information'),
                              icon: Icons.auto_stories_outlined,
                              children: [
                                _textField(
                                  _isbnController,
                                  'ISBN',
                                  icon: Icons.qr_code_2_rounded,
                                ),
                                _textField(
                                  _publisherController,
                                  l10n('Yayınevi', 'Publisher'),
                                  icon: Icons.business_outlined,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _numberField(
                                        _publishYearController,
                                        l10n('Basım yılı', 'Publication year'),
                                        icon: Icons.calendar_today_outlined,
                                        min: 0,
                                        max: DateTime.now().year + 1,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _numberField(
                                        _pageCountController,
                                        l10n('Sayfa sayısı', 'Page count'),
                                        icon: Icons.description_outlined,
                                        min: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _FormSection(
                              title: l10n('Kütüphane Bilgileri', 'Library Information'),
                              icon: Icons.shelves,
                              children: [
                                LayoutBuilder(
                                  builder: (context, inner) {
                                    final split = inner.maxWidth >= 680;
                                    if (!split) {
                                      return Column(
                                        children: [
                                          _textField(
                                            _categoryController,
                                            l10n('Kategori', 'Category'),
                                            icon: Icons.category_outlined,
                                          ),
                                          const SizedBox(height: 12),
                                          _textField(
                                            _locationController,
                                            l10n('Raf / konum', 'Shelf / location'),
                                            icon: Icons.location_on_outlined,
                                          ),
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: _textField(
                                            _categoryController,
                                            l10n('Kategori', 'Category'),
                                            icon: Icons.category_outlined,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _textField(
                                            _locationController,
                                            l10n('Raf / konum', 'Shelf / location'),
                                            icon: Icons.location_on_outlined,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerHighest
                                        .withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n(
                                            'Müsaitlik fiziksel nüsha ve emanet durumuna göre otomatik yönetilir.',
                                            'Availability is managed automatically based on physical copies and loan status.',
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: Text(l10n('Vazgeç', 'Cancel')),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveBook,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  _isEditing ? l10n('Güncelle', 'Update') : l10n('Kitabı Kaydet', 'Save Book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    required IconData icon,
    bool required = false,
    bool autofocus = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return l10n('$label zorunlu', '$label is required');
        }
        return null;
      },
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    required IconData icon,
    int? min,
    int? max,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (value) {
        final raw = value?.trim() ?? '';
        if (raw.isEmpty) return null;
        final number = int.tryParse(raw);
        if (number == null) return l10n('Geçerli bir sayı girin', 'Enter a valid number');
        if (min != null && number < min) {
          return l10n('En az $min olmalı', 'Must be at least $min');
        }
        if (max != null && number > max) {
          return l10n('En fazla $max olmalı', 'Must be at most $max');
        }
        return null;
      },
    );
  }
}

class _FormIntro extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FormIntro({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: scheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._withSpacing(children),
        ],
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> widgets) {
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i != widgets.length - 1) {
        result.add(const SizedBox(height: 12));
      }
    }
    return result;
  }
}

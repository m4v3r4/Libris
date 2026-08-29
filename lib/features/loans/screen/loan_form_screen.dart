import 'package:flutter/material.dart';
import 'package:libris/common/localization/app_localization.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/common/models/member.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:libris/features/books/models/book_copy.dart';

class LoanFormScreen extends StatefulWidget {
  final Loan? loan;

  const LoanFormScreen({super.key, this.loan});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Book? _selectedBook;
  Member? _selectedMember;
  BookCopy? _selectedCopy;
  List<BookCopy> _availableCopies = [];
  bool _loadingCopies = false;
  bool _isSaving = false;

  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));

  bool get _isEditing => widget.loan != null;

  @override
  void initState() {
    super.initState();
    if (widget.loan != null) {
      _dueDate = widget.loan!.dueDate;
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    final loan = widget.loan!;
    final book = await _databaseHelper.getBookById(loan.bookId);
    final member = await _databaseHelper.getMemberById(loan.memberId);
    final copy = loan.copyId == null
        ? null
        : await _databaseHelper.getBookCopyById(loan.copyId!);

    if (!mounted) return;
    setState(() {
      _selectedBook = book;
      _selectedMember = member;
      _selectedCopy = copy;
      _availableCopies = copy == null ? [] : [copy];
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: l10n('Teslim tarihi seçin', 'Select due date'),
      cancelText: l10n('İptal', 'Cancel'),
      confirmText: l10n('Seç', 'Select'),
    );

    if (!mounted || picked == null) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _selectBook(Book book) async {
    setState(() {
      _selectedBook = book;
      _selectedCopy = null;
      _availableCopies = [];
      _loadingCopies = true;
    });

    final copies = await _databaseHelper.getAvailableBookCopies(book.id!);
    if (!mounted) return;
    setState(() {
      _availableCopies = copies;
      _selectedCopy = copies.length == 1 ? copies.first : null;
      _loadingCopies = false;
    });

    if (copies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n(
              'Bu kitabın müsait fiziksel nüshası yok.',
              'This book has no available physical copies.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _saveLoan() async {
    if (_isSaving) return;
    if (_selectedBook == null ||
        _selectedMember == null ||
        _selectedCopy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n(
              'Lütfen kitap, nüsha ve üye seçiniz.',
              'Please select a book, copy, and member.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final loan = Loan(
      id: widget.loan?.id,
      bookId: _selectedBook!.id!,
      memberId: _selectedMember!.id!,
      copyId: _selectedCopy!.id,
      loanDate: widget.loan?.loanDate ?? DateTime.now(),
      dueDate: _dueDate,
      returnedAt: widget.loan?.returnedAt,
      createdAt: widget.loan?.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      if (_isEditing) {
        await _databaseHelper.updateLoan(loan);
      } else {
        await _databaseHelper.createLoan(loan);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMemberPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return _MemberSearchSheet(
              databaseHelper: _databaseHelper,
              onSelect: (member) {
                setState(() => _selectedMember = member);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showBookPicker() {
    if (_isEditing) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return _BookSearchSheet(
              bookService: _databaseHelper,
              onSelect: (book) {
                Navigator.pop(context);
                _selectBook(book);
              },
            );
          },
        );
      },
    );
  }

  void _showCopyPicker() {
    if (_isEditing || _selectedBook == null || _loadingCopies) return;
    if (_availableCopies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n(
              'Seçilebilecek müsait nüsha yok.',
              'There are no available copies to select.',
            ),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        children: [
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(
              l10n('Nüsha Seç', 'Select Copy'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              l10n(
                'Müsait fiziksel nüshalardan birini seçin.',
                'Choose one of the available physical copies.',
              ),
            ),
          ),
          ..._availableCopies.map(
            (copy) => ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(copy.inventoryCode),
              subtitle: Text(l10n('Müsait', 'Available')),
              selected: _selectedCopy?.id == copy.id,
              trailing: _selectedCopy?.id == copy.id
                  ? const Icon(Icons.check_circle_rounded)
                  : null,
              onTap: () {
                setState(() => _selectedCopy = copy);
                Navigator.pop(sheetContext);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n('Emanet Düzenle', 'Edit Loan') : l10n('Emanet Ver', 'Create Loan'),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LoanIntro(isEditing: _isEditing),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 760;
                      final width = twoColumns
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: width,
                            child: _LoanSection(
                              title: l10n('Kitap ve Nüsha', 'Book and Copy'),
                              icon: Icons.menu_book_rounded,
                              children: [
                                _SelectionField(
                                  label: l10n('Kitap', 'Book'),
                                  icon: Icons.auto_stories_outlined,
                                  value: _selectedBook == null
                                      ? l10n(
                                          'Kitap seçmek için dokunun',
                                          'Tap to select a book',
                                        )
                                      : '${_selectedBook!.title} · ${_selectedBook!.author}',
                                  selected: _selectedBook != null,
                                  locked: _isEditing,
                                  onTap: _isEditing ? null : _showBookPicker,
                                ),
                                const SizedBox(height: 12),
                                _SelectionField(
                                  label: l10n('Fiziksel Nüsha', 'Physical Copy'),
                                  icon: Icons.inventory_2_outlined,
                                  value: _selectedCopy?.inventoryCode ??
                                      (_selectedBook == null
                                          ? l10n('Önce kitap seçin', 'Select a book first')
                                          : _availableCopies.isEmpty &&
                                                  !_loadingCopies
                                              ? l10n('Müsait nüsha yok', 'No available copies')
                                              : l10n(
                                                  'Nüsha seçmek için dokunun',
                                                  'Tap to select a copy',
                                                )),
                                  selected: _selectedCopy != null,
                                  locked: _isEditing,
                                  loading: _loadingCopies,
                                  onTap: _isEditing ? null : _showCopyPicker,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _LoanSection(
                              title: l10n('Üye ve Teslim', 'Member and Due Date'),
                              icon: Icons.person_rounded,
                              children: [
                                _SelectionField(
                                  label: l10n('Üye', 'Member'),
                                  icon: Icons.person_outline_rounded,
                                  value: _selectedMember?.name ??
                                      l10n(
                                        'Üye seçmek için dokunun',
                                        'Tap to select a member',
                                      ),
                                  selected: _selectedMember != null,
                                  onTap: _showMemberPicker,
                                ),
                                const SizedBox(height: 12),
                                _SelectionField(
                                  label: l10n('Teslim Tarihi', 'Due Date'),
                                  icon: Icons.event_outlined,
                                  value: _formatDate(_dueDate),
                                  selected: true,
                                  trailing: const Icon(
                                    Icons.calendar_month_rounded,
                                  ),
                                  onTap: _pickDueDate,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isEditing
                                ? l10n(
                                    'Emanet kaydını düzenlerken kitap ve fiziksel nüsha değiştirilemez; üye ve teslim tarihi güncellenebilir.',
                                    'When editing a loan, the book and physical copy cannot be changed; the member and due date can be updated.',
                                  )
                                : l10n(
                                    'Yalnızca müsait fiziksel nüshalar seçilebilir. Varsayılan teslim süresi 14 gündür.',
                                    'Only available physical copies can be selected. The default loan period is 14 days.',
                                  ),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.maybePop(context),
                    child: Text(l10n('Vazgeç', 'Cancel')),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveLoan,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isEditing
                                ? Icons.save_outlined
                                : Icons.swap_horiz_rounded,
                          ),
                    label: Text(
                      _isEditing ? l10n('Güncelle', 'Update') : l10n('Emanet Ver', 'Create Loan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoanIntro extends StatelessWidget {
  final bool isEditing;

  const _LoanIntro({required this.isEditing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.swap_horiz_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? l10n('Emanet kaydını güncelleyin', 'Update loan record')
                      : l10n('Yeni emanet işlemi', 'New loan transaction'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n(
                    'Kitap, fiziksel nüsha, üye ve teslim tarihini tek ekrandan yönetin.',
                    'Manage the book, physical copy, member, and due date from one screen.',
                  ),
                  style: textTheme.bodyMedium?.copyWith(
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

class _LoanSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _LoanSection({
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
              Icon(icon, size: 19, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SelectionField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final bool locked;
  final bool loading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SelectionField({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    this.locked = false,
    this.loading = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        isEmpty: !selected,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : trailing ??
                  Icon(
                    locked ? Icons.lock_outline_rounded : Icons.expand_more_rounded,
                  ),
        ),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

class _MemberSearchSheet extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  final ValueChanged<Member> onSelect;

  const _MemberSearchSheet({
    required this.databaseHelper,
    required this.onSelect,
  });

  @override
  State<_MemberSearchSheet> createState() => _MemberSearchSheetState();
}

class _MemberSearchSheetState extends State<_MemberSearchSheet> {
  List<Member> _results = [];
  String _query = '';

  Future<void> _search(String query) async {
    _query = query;
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final res = await widget.databaseHelper.searchMembers(query);
    if (!mounted) return;
    setState(() => _results = res);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                l10n('Üye Seç', 'Select Member'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n('Kapat', 'Close'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n(
                'İsim, telefon veya e-posta ara...',
                'Search name, phone, or email...',
              ),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: _search,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty
                          ? l10n('Aramaya başlayın', 'Start searching')
                          : l10n('Sonuç bulunamadı', 'No results found'),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = _results[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline_rounded),
                        ),
                        title: Text(member.name),
                        subtitle: Text(member.phone ?? member.email ?? ''),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => widget.onSelect(member),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookSearchSheet extends StatefulWidget {
  final DatabaseHelper bookService;
  final ValueChanged<Book> onSelect;

  const _BookSearchSheet({
    required this.bookService,
    required this.onSelect,
  });

  @override
  State<_BookSearchSheet> createState() => _BookSearchSheetState();
}

class _BookSearchSheetState extends State<_BookSearchSheet> {
  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final books = await widget.bookService.getBooks();
    final availableBooks = books.where((book) => book.isAvailable).toList();
    if (!mounted) return;
    setState(() {
      _allBooks = availableBooks;
      _filteredBooks = availableBooks;
      _loading = false;
    });
  }

  void _filter(String query) {
    final lower = query.trim().toLowerCase();
    setState(() {
      _filteredBooks = _allBooks.where((book) {
        return book.title.toLowerCase().contains(lower) ||
            book.author.toLowerCase().contains(lower) ||
            (book.isbn?.toLowerCase().contains(lower) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                l10n('Kitap Seç', 'Select Book'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n('Kapat', 'Close'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n(
                'Başlık, yazar veya ISBN ara...',
                'Search title, author, or ISBN...',
              ),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                    ? Center(
                        child: Text(
                          l10n(
                            'Müsait kitap bulunamadı',
                            'No available books found',
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredBooks.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.menu_book_outlined),
                            ),
                            title: Text(book.title),
                            subtitle: Text(book.author),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => widget.onSelect(book),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

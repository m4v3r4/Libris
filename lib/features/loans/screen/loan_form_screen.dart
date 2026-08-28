import 'package:flutter/material.dart';
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
        const SnackBar(content: Text('Bu kitabın müsait fiziksel nüshası yok.')),
      );
    }
  }

  Future<void> _saveLoan() async {
    if (_selectedBook == null ||
        _selectedMember == null ||
        _selectedCopy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kitap, nüsha ve üye seçiniz.')),
      );
      return;
    }

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
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showMemberPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
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
        const SnackBar(content: Text('Seçilebilecek müsait nüsha yok.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Nüsha Seç',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ..._availableCopies.map(
              (copy) => ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(copy.inventoryCode),
                subtitle: const Text('Müsait'),
                selected: _selectedCopy?.id == copy.id,
                onTap: () {
                  setState(() => _selectedCopy = copy);
                  Navigator.pop(sheetContext);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Emanet Düzenle' : 'Emanet Ver'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              InkWell(
                onTap: _isEditing ? null : _showBookPicker,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Kitap Seç',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.book),
                    suffixIcon: _isEditing
                        ? const Icon(Icons.lock_outline)
                        : const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedBook != null
                        ? '${_selectedBook!.title} (${_selectedBook!.author})'
                        : 'Kitap seçmek için dokunun',
                    style: TextStyle(
                      color: _selectedBook != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _showCopyPicker,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fiziksel Nüsha',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    suffixIcon: _isEditing
                        ? const Icon(Icons.lock_outline)
                        : _loadingCopies
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedCopy?.inventoryCode ??
                        (_selectedBook == null
                            ? 'Önce kitap seçiniz'
                            : 'Nüsha seçmek için dokunun'),
                    style: TextStyle(
                      color: _selectedCopy != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _showMemberPicker,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Üye Seç',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedMember != null
                        ? _selectedMember!.name
                        : 'Üye seçmek için dokunun',
                    style: TextStyle(
                      color: _selectedMember != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Teslim Tarihi'),
                subtitle: Text(_dueDate.toLocal().toString()),
                trailing: IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: _pickDueDate,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveLoan,
                child: Text(_isEditing ? 'Güncelle' : 'Emanet Ver'),
              ),
            ],
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Üye ara (isim, tel, e-posta)...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _search,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _results.isEmpty && _query.isNotEmpty
                ? const Center(child: Text('Sonuç bulunamadı'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final member = _results[index];
                      return ListTile(
                        title: Text(member.name),
                        subtitle: Text(member.phone ?? member.email ?? ''),
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
    });
  }

  void _filter(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filteredBooks = _allBooks.where((b) {
        return b.title.toLowerCase().contains(lower) ||
            b.author.toLowerCase().contains(lower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Müsait kitap ara (başlık, yazar)...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _filteredBooks.isEmpty
                ? const Center(child: Text('Müsait kitap bulunamadı'))
                : ListView.builder(
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      return ListTile(
                        title: Text(book.title),
                        subtitle: Text(book.author),
                        trailing: const Icon(Icons.check_circle_outline),
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

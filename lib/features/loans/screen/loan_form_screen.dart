import 'package:flutter/material.dart';
import 'package:libris/common/services/database_helper.dart';
import 'package:libris/features/books/models/book.dart';
import 'package:libris/common/models/loan.dart';
import 'package:libris/features/members/models/member.dart';

class LoanFormScreen extends StatefulWidget {
  final Loan? loan;

  const LoanFormScreen({super.key, this.loan});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _loanService = DatabaseHelper.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  // BookService'in projenizde var olduğunu varsayıyoruz

  Book? _selectedBook;
  Member? _selectedMember;

  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));

  @override
  void initState() {
    super.initState();
    if (widget.loan != null) {
      _dueDate = widget.loan!.dueDate;
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    final book = await _databaseHelper.getBookById(widget.loan!.bookId);
    final member = await _databaseHelper.getMemberById(widget.loan!.memberId);
    if (mounted) {
      setState(() {
        _selectedBook = book;
        _selectedMember = member;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _saveLoan() async {
    if (_selectedBook == null || _selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kitap ve üye seçiniz.')),
      );
      return;
    }

    final loan = Loan(
      id: widget.loan?.id, // Düzenleme ise ID korunmalı
      bookId: _selectedBook!.id!,
      memberId: _selectedMember!.id!,
      loanDate: widget.loan?.loanDate ?? DateTime.now(),
      dueDate: _dueDate,
      returnedAt: widget.loan?.returnedAt,
    );

    try {
      if (widget.loan != null) {
        await _loanService.updateLoan(loan);
      } else {
        await _loanService.createLoan(loan);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // Üye Seçimi İçin Modal
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

  // Kitap Seçimi İçin Modal
  void _showBookPicker() {
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
                setState(() => _selectedBook = book);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loan != null ? 'Emanet Düzenle' : 'Emanet Ver'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // KİTAP SEÇİMİ
              InkWell(
                onTap: _showBookPicker,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Kitap Seç',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book),
                    suffixIcon: Icon(Icons.arrow_drop_down),
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

              // ÜYE SEÇİMİ
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
                child: const Text('Emanet Ver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Üye Arama ve Seçme Widget'ı
class _MemberSearchSheet extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  final Function(Member) onSelect;

  const _MemberSearchSheet({
    super.key,
    required this.databaseHelper,
    required this.onSelect,
  });

  @override
  State<_MemberSearchSheet> createState() => _MemberSearchSheetState();
}

class _MemberSearchSheetState extends State<_MemberSearchSheet> {
  List<Member> _results = [];
  String _query = '';

  void _search(String query) async {
    _query = query;
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final res = await widget.databaseHelper.searchMembers(query);
    if (mounted) setState(() => _results = res);
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

/// Kitap Arama ve Seçme Widget'ı
class _BookSearchSheet extends StatefulWidget {
  final DatabaseHelper bookService;
  final Function(Book) onSelect;

  const _BookSearchSheet({
    super.key,
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
    // BookService'de searchBooks yoksa bile getBooks ile çekip
    // burada filtreleyebiliriz.
    final books = await widget.bookService.getBooks();
    if (mounted) {
      setState(() {
        _allBooks = books;
        _filteredBooks = books;
      });
    }
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
              hintText: 'Kitap ara (başlık, yazar)...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredBooks.length,
              itemBuilder: (context, index) {
                final book = _filteredBooks[index];
                return ListTile(
                  title: Text(book.title),
                  subtitle: Text(book.author),
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

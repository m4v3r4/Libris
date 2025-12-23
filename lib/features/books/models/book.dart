class Book {
  final int? id;

  final String title;
  final String author;
  final String description;

  final String? isbn;
  final String? publisher;
  final int? publishYear;
  final int? pageCount;
  final String? category;
  final String? location;

  final bool isAvailable;

  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.description,
    this.isbn,
    this.publisher,
    this.publishYear,
    this.pageCount,
    this.category,
    this.location,
    this.isAvailable = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// SQLite için
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'isbn': isbn,
      'publisher': publisher,
      'publishYear': publishYear,
      'pageCount': pageCount,
      'category': category,
      'location': location,
      'isAvailable': isAvailable ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      title: map['title'],
      author: map['author'],
      description: map['description'],
      isbn: map['isbn'],
      publisher: map['publisher'],
      publishYear: map['publishYear'],
      pageCount: map['pageCount'],
      category: map['category'],
      location: map['location'],
      isAvailable: map['isAvailable'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  /// Güncelleme için kullanışlı
  Book copyWith({
    int? id,
    String? title,
    String? author,
    String? description,
    String? isbn,
    String? publisher,
    int? publishYear,
    int? pageCount,
    String? category,
    String? location,
    bool? isAvailable,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      isbn: isbn ?? this.isbn,
      publisher: publisher ?? this.publisher,
      publishYear: publishYear ?? this.publishYear,
      pageCount: pageCount ?? this.pageCount,
      category: category ?? this.category,
      location: location ?? this.location,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, available: $isAvailable)';
  }
}

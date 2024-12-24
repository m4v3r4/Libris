class CustomBook {
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String thumbnail;
  final String publisher;
  final String publishedDate;
  final int pageCount;
  final String shelf;
  final String rack;
  final int isAvailable;
  final String? currentUserId;
  final String isbn;

  CustomBook({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.thumbnail,
    required this.publisher,
    required this.publishedDate,
    required this.pageCount,
    required this.shelf,
    required this.rack,
    required this.isAvailable,
    required this.currentUserId,
    required this.isbn,
  });

  // fromJson metodu
  factory CustomBook.fromJson(Map<String, dynamic> json) {
    return CustomBook(
      id: json['id'],
      title: json['title'],
      authors: (json['authors'] as String)
          .split(', '), // authors verisini virgülle ayır
      description: json['description'] ??
          'Açıklama yok', // Eğer null ise varsayılan açıklama
      thumbnail: json['thumbnail'],
      publisher: json['publisher'],
      publishedDate: json['publishedDate'],
      pageCount: json['pageCount'],
      shelf: json['shelf'],
      rack: json['rack'],
      isAvailable: json['isAvailable'],
      currentUserId: json['currentUserId'],
      isbn: json['isbn'],
    );
  }

  // toMap metodu
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'authors': authors.join(', '), // authors listesini virgülle ayır
      'description': description,
      'thumbnail': thumbnail,
      'publisher': publisher,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'shelf': shelf,
      'rack': rack,
      'isAvailable': isAvailable,
      'currentUserId': currentUserId,
      'isbn': isbn,
    };
  }
}

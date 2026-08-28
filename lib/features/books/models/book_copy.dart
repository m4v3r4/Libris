enum BookCopyStatus { available, loaned, lost, maintenance }

class BookCopy {
  final int? id;
  final int bookId;
  final String inventoryCode;
  final BookCopyStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookCopy({
    this.id,
    required this.bookId,
    required this.inventoryCode,
    this.status = BookCopyStatus.available,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isAvailable => status == BookCopyStatus.available;
  bool get isLoaned => status == BookCopyStatus.loaned;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'inventoryCode': inventoryCode,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BookCopy.fromMap(Map<String, dynamic> map) {
    final statusName = map['status'] as String? ?? BookCopyStatus.available.name;
    final status = BookCopyStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => BookCopyStatus.available,
    );

    return BookCopy(
      id: map['id'] as int?,
      bookId: map['bookId'] as int,
      inventoryCode: map['inventoryCode'] as String,
      status: status,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  BookCopy copyWith({
    int? id,
    int? bookId,
    String? inventoryCode,
    BookCopyStatus? status,
  }) {
    return BookCopy(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      inventoryCode: inventoryCode ?? this.inventoryCode,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

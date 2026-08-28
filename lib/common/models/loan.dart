class Loan {
  final int? id;

  final int bookId;
  final int memberId;
  final int? copyId;

  final DateTime loanDate;
  final DateTime dueDate;
  final DateTime? returnedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    this.id,
    required this.bookId,
    required this.memberId,
    this.copyId,
    required this.loanDate,
    required this.dueDate,
    this.returnedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isReturned => returnedAt != null;

  bool get isOverdue => !isReturned && DateTime.now().isAfter(dueDate);

  int get overdueDays {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'memberId': memberId,
      'copyId': copyId,
      'loanDate': loanDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'returnedAt': returnedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      bookId: map['bookId'] as int,
      memberId: map['memberId'] as int,
      copyId: map['copyId'] as int?,
      loanDate: DateTime.parse(map['loanDate'] as String),
      dueDate: DateTime.parse(map['dueDate'] as String),
      returnedAt: map['returnedAt'] != null
          ? DateTime.parse(map['returnedAt'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Loan copyWith({
    int? id,
    int? bookId,
    int? memberId,
    int? copyId,
    DateTime? loanDate,
    DateTime? dueDate,
    DateTime? returnedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      memberId: memberId ?? this.memberId,
      copyId: copyId ?? this.copyId,
      loanDate: loanDate ?? this.loanDate,
      dueDate: dueDate ?? this.dueDate,
      returnedAt: returnedAt ?? this.returnedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

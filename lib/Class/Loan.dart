class Loan {
  final String id;
  String userId;
  String userFirstName;
  String userLastName;
  final String bookId;
  final String bookName;
  DateTime loanDate;
  DateTime? returnDate;

  Loan({
    required this.id,
    required this.userId,
    required this.userFirstName,
    required this.userLastName,
    required this.bookId,
    required this.bookName,
    required this.loanDate,
    this.returnDate,
  });

  // JSON dönüşümü
  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      userId: json['userId'],
      userFirstName: json['userFirstName'],
      userLastName: json['userLastName'],
      bookId: json['bookId'],
      bookName: json['bookName'],
      loanDate: DateTime.parse(json['loanDate']),
      returnDate: json['returnDate'] != null
          ? DateTime.parse(json['returnDate'])
          : null,
    );
  }

  // Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userFirstName': userFirstName,
      'userLastName': userLastName,
      'bookId': bookId,
      'bookName': bookName,
      'loanDate': loanDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
    };
  }
}

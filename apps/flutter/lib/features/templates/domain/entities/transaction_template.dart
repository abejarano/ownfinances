class TransactionTemplate {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String type; // 'income', 'expense', 'transfer'
  final String currency;
  final String? categoryId;
  final String? fromAccountId;
  final String? toAccountId;
  final String? note;
  final List<String>? tags;

  const TransactionTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.type,
    required this.currency,
    this.categoryId,
    this.fromAccountId,
    this.toAccountId,
    this.note,
    this.tags,
  });

  factory TransactionTemplate.fromJson(Map<String, dynamic> json) {
    return TransactionTemplate(
      id: json['templateId'] ?? json['id'],
      userId: json['userId'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      currency: json['currency'],
      categoryId: json['categoryId'],
      fromAccountId: json['fromAccountId'],
      toAccountId: json['toAccountId'],
      note: json['note'],
      tags: (json['tags'] as List?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'amount': amount,
      'type': type,
      'currency': currency,
      'categoryId': categoryId,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'note': note,
      'tags': tags,
    };
  }
}

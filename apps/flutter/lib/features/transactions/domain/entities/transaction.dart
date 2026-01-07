class Transaction {
  final String id;
  final String type;
  final DateTime date;
  final double amount;
  final String currency;
  final String? categoryId;
  final String? fromAccountId;
  final String? toAccountId;
  final String? note;
  final List<String> tags;
  final String status;
  final DateTime? clearedAt;
  final String? recurringRuleId;

  const Transaction({
    required this.id,
    required this.type,
    required this.date,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.note,
    required this.tags,
    required this.status,
    required this.clearedAt,
    this.recurringRuleId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: (json["transactionId"] ?? json["id"]) as String,
      type: json["type"] as String,
      date: DateTime.parse(json["date"] as String),
      amount: (json["amount"] as num?)?.toDouble() ?? 0,
      currency: json["currency"] as String? ?? "BRL",
      categoryId: json["categoryId"] as String?,
      fromAccountId: json["fromAccountId"] as String?,
      toAccountId: json["toAccountId"] as String?,
      note: json["note"] as String?,
      tags:
          (json["tags"] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      status: json["status"] as String? ?? "pending",
      clearedAt: json["clearedAt"] != null
          ? DateTime.tryParse(json["clearedAt"] as String)
          : null,
      recurringRuleId: json["recurringRuleId"] as String?,
    );
  }
}

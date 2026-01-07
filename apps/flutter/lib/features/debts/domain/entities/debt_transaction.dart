class DebtTransaction {
  final String id;
  final String debtId;
  final DateTime date;
  final String type;
  final double amount;
  final String? accountId;
  final String? note;

  const DebtTransaction({
    required this.id,
    required this.debtId,
    required this.date,
    required this.type,
    required this.amount,
    required this.accountId,
    required this.note,
  });

  factory DebtTransaction.fromJson(Map<String, dynamic> json) {
    return DebtTransaction(
      id: (json["debtTransactionId"] ?? json["id"]) as String,
      debtId: json["debtId"] as String,
      date: DateTime.parse(json["date"] as String),
      type: json["type"] as String,
      amount: (json["amount"] as num?)?.toDouble() ?? 0,
      accountId: json["accountId"] as String?,
      note: json["note"] as String?,
    );
  }
}

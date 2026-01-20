class Debt {
  final String id;
  final String name;
  final String type;
  final String currency;
  final double currentBalance;
  final int? dueDay;
  final double? minimumPayment;
  final double? interestRateAnnual;
  final String? linkedAccountId;
  final String? paymentAccountId;
  final double? initialBalance;
  final bool isActive;
  final double amountDue;
  final double creditBalance;

  const Debt({
    required this.id,
    required this.name,
    required this.type,
    this.linkedAccountId,
    this.paymentAccountId,
    required this.currency,
    required this.currentBalance,
    required this.dueDay,
    required this.minimumPayment,
    required this.interestRateAnnual,
    this.initialBalance,
    required this.isActive,
    required this.amountDue,
    required this.creditBalance,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: (json["debtId"] ?? json["id"]) as String,
      name: json["name"] as String,
      type: json["type"] as String,
      linkedAccountId: json["linkedAccountId"] as String?,
      paymentAccountId: json["paymentAccountId"] as String?,
      currency: json["currency"] as String? ?? "BRL",
      currentBalance: (json["currentBalance"] as num?)?.toDouble() ?? 0,
      dueDay: json["dueDay"] as int?,
      minimumPayment: (json["minimumPayment"] as num?)?.toDouble(),
      interestRateAnnual: (json["interestRateAnnual"] as num?)?.toDouble(),
      initialBalance: (json["initialBalance"] as num?)?.toDouble(),
      isActive: json["isActive"] as bool? ?? true,
      amountDue: (json["amountDue"] as num?)?.toDouble() ?? 0.0,
      creditBalance: (json["creditBalance"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

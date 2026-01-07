class DebtSummary {
  final double balanceComputed;
  final double paymentsThisMonth;
  final DateTime? nextDueDate;

  const DebtSummary({
    required this.balanceComputed,
    required this.paymentsThisMonth,
    required this.nextDueDate,
  });

  factory DebtSummary.fromJson(Map<String, dynamic> json) {
    return DebtSummary(
      balanceComputed: (json["balanceComputed"] as num?)?.toDouble() ?? 0,
      paymentsThisMonth:
          (json["paymentsThisMonth"] as num?)?.toDouble() ?? 0,
      nextDueDate: json["nextDueDate"] != null
          ? DateTime.parse(json["nextDueDate"] as String)
          : null,
    );
  }
}

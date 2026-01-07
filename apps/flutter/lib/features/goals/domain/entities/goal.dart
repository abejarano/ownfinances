class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final String currency;
  final DateTime startDate;
  final DateTime? targetDate;
  final double? monthlyContribution;
  final String? linkedAccountId;
  final bool isActive;

  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currency,
    required this.startDate,
    required this.targetDate,
    required this.monthlyContribution,
    required this.linkedAccountId,
    required this.isActive,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: (json["goalId"] ?? json["id"]) as String,
      name: json["name"] as String,
      targetAmount: (json["targetAmount"] as num?)?.toDouble() ?? 0,
      currency: json["currency"] as String? ?? "BRL",
      startDate: DateTime.parse(json["startDate"] as String),
      targetDate: json["targetDate"] != null
          ? DateTime.parse(json["targetDate"] as String)
          : null,
      monthlyContribution:
          (json["monthlyContribution"] as num?)?.toDouble(),
      linkedAccountId: json["linkedAccountId"] as String?,
      isActive: json["isActive"] as bool? ?? true,
    );
  }
}

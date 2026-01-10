class Account {
  final String id;
  final String name;
  final String type;
  final String? bankType;
  final String currency;
  final bool isActive;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.bankType,
    required this.currency,
    required this.isActive,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: (json["accountId"] ?? json["id"]) as String,
      name: json["name"] as String,
      type: json["type"] as String,
      bankType: json["bankType"] as String?,
      currency: json["currency"] as String? ?? "BRL",
      isActive: json["isActive"] as bool? ?? true,
    );
  }
}

class AccountBalance {
  final String accountId;
  final double balance;

  const AccountBalance({
    required this.accountId,
    required this.balance,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      accountId: json["accountId"] as String? ?? "",
      balance: (json["balance"] as num?)?.toDouble() ?? 0,
    );
  }
}

class ReportBalances {
  final DateTime start;
  final DateTime end;
  final List<AccountBalance> balances;

  const ReportBalances({
    required this.start,
    required this.end,
    required this.balances,
  });

  factory ReportBalances.fromJson(Map<String, dynamic> json) {
    final range = (json["range"] as Map<String, dynamic>?) ?? {};
    final startRaw = range["start"] as String?;
    final endRaw = range["end"] as String?;
    return ReportBalances(
      start: startRaw == null ? DateTime.now() : DateTime.parse(startRaw),
      end: endRaw == null ? DateTime.now() : DateTime.parse(endRaw),
      balances: (json["balances"] as List<dynamic>? ?? [])
          .map((item) => AccountBalance.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
    );
  }
}

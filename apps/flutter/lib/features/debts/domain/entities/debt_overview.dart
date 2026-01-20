class DebtOverview {
  final double totalAmountDue;
  final double totalPaidThisMonth;
  final DebtOverviewItem? nextDue;
  final DebtOverviewFlags flags;
  final DebtOverviewCounts counts;

  DebtOverview({
    required this.totalAmountDue,
    required this.totalPaidThisMonth,
    this.nextDue,
    required this.flags,
    required this.counts,
  });

  factory DebtOverview.fromJson(Map<String, dynamic> json) {
    return DebtOverview(
      totalAmountDue: (json['totalAmountDue'] as num).toDouble(),
      totalPaidThisMonth: (json['totalPaidThisMonth'] as num).toDouble(),
      nextDue: json['nextDue'] != null
          ? DebtOverviewItem.fromJson(json['nextDue'])
          : null,
      flags: DebtOverviewFlags.fromJson(json['flags']),
      counts: DebtOverviewCounts.fromJson(json['counts']),
    );
  }
}

class DebtOverviewItem {
  final String debtId;
  final String name;
  final DateTime date;
  final double amountDue;
  final bool isOverdue;

  DebtOverviewItem({
    required this.debtId,
    required this.name,
    required this.date,
    required this.amountDue,
    required this.isOverdue,
  });

  factory DebtOverviewItem.fromJson(Map<String, dynamic> json) {
    return DebtOverviewItem(
      debtId: json['debtId'] as String,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      amountDue: (json['amountDue'] as num).toDouble(),
      isOverdue: json['isOverdue'] as bool,
    );
  }
}

class DebtOverviewFlags {
  final bool hasOverdue;

  DebtOverviewFlags({required this.hasOverdue});

  factory DebtOverviewFlags.fromJson(Map<String, dynamic> json) {
    return DebtOverviewFlags(hasOverdue: json['hasOverdue'] as bool);
  }
}

class DebtOverviewCounts {
  final int activeDebts;

  DebtOverviewCounts({required this.activeDebts});

  factory DebtOverviewCounts.fromJson(Map<String, dynamic> json) {
    return DebtOverviewCounts(activeDebts: json['activeDebts'] as int);
  }
}

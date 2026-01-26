class BudgetLine {
  final String categoryId;
  final double plannedAmount;

  const BudgetLine({required this.categoryId, required this.plannedAmount});

  factory BudgetLine.fromJson(Map<String, dynamic> json) {
    return BudgetLine(
      categoryId: json["categoryId"] as String,
      plannedAmount: (json["plannedAmount"] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "categoryId": categoryId,
    "plannedAmount": plannedAmount,
  };
}

class BudgetDebtPayment {
  final String debtId;
  final double plannedAmount;

  const BudgetDebtPayment({
    required this.debtId,
    required this.plannedAmount,
  });

  factory BudgetDebtPayment.fromJson(Map<String, dynamic> json) {
    return BudgetDebtPayment(
      debtId: json["debtId"] as String,
      plannedAmount: (json["plannedAmount"] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "debtId": debtId,
    "plannedAmount": plannedAmount,
  };
}

class Budget {
  final String id;
  final String periodType;
  final DateTime startDate;
  final DateTime endDate;
  final List<BudgetLine> lines;
  final List<BudgetDebtPayment> debtPayments;

  const Budget({
    required this.id,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.lines,
    required this.debtPayments,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: (json["budgetId"] ?? json["id"]) as String,
      periodType: json["periodType"] as String,
      startDate: DateTime.parse(json["startDate"] as String),
      endDate: DateTime.parse(json["endDate"] as String),
      lines: (json["lines"] as List<dynamic>? ?? [])
          .map((item) => BudgetLine.fromJson(item as Map<String, dynamic>))
          .toList(),
      debtPayments: (json["debtPayments"] as List<dynamic>? ?? [])
          .map(
            (item) => BudgetDebtPayment.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

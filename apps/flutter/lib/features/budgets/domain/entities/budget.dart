class BudgetPlanEntry {
  final String id;
  final double amount;
  final String currency;
  final String? description;
  final DateTime createdAt;

  const BudgetPlanEntry({
    required this.id,
    required this.amount,
    required this.currency,
    required this.createdAt,
    this.description,
  });

  factory BudgetPlanEntry.fromJson(Map<String, dynamic> json) {
    return BudgetPlanEntry(
      id: json["entryId"] as String,
      amount: (json["amount"] as num?)?.toDouble() ?? 0,
      currency:
          json["currency"] as String? ?? "BRL", // Default fallback if missing
      description: json["description"] as String?,
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    "entryId": id,
    "amount": amount,
    "currency": currency,
    "description": description,
    "createdAt": createdAt.toIso8601String(),
  };
}

class BudgetCategoryPlan {
  final String categoryId;
  final Map<String, double> plannedTotal;
  final List<BudgetPlanEntry> entries;

  const BudgetCategoryPlan({
    required this.categoryId,
    required this.plannedTotal,
    required this.entries,
  });

  factory BudgetCategoryPlan.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryPlan(
      categoryId: json["categoryId"] as String,
      plannedTotal:
          (json["plannedTotal"] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
      entries: (json["entries"] as List<dynamic>? ?? [])
          .map((item) => BudgetPlanEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "categoryId": categoryId,
    "plannedTotal": plannedTotal,
    "entries": entries.map((entry) => entry.toJson()).toList(),
  };
}

class BudgetDebtPayment {
  final String debtId;
  final double plannedAmount;

  const BudgetDebtPayment({required this.debtId, required this.plannedAmount});

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
  final List<BudgetCategoryPlan> categories;
  final List<BudgetDebtPayment> debtPayments;

  const Budget({
    required this.id,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.categories,
    required this.debtPayments,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: (json["budgetId"] ?? json["id"]) as String,
      periodType: json["periodType"] as String,
      startDate: DateTime.parse(json["startDate"] as String),
      endDate: DateTime.parse(json["endDate"] as String),
      categories: (json["categories"] as List<dynamic>? ?? [])
          .map(
            (item) => BudgetCategoryPlan.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      debtPayments: (json["debtPayments"] as List<dynamic>? ?? [])
          .map(
            (item) => BudgetDebtPayment.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

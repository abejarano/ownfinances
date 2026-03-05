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

class BudgetDebtPlan {
  final String debtId;
  final double plannedAmount;
  final String? note;

  const BudgetDebtPlan({
    required this.debtId,
    required this.plannedAmount,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {'debtId': debtId, 'plannedAmount': plannedAmount, 'note': note};
  }

  factory BudgetDebtPlan.fromJson(Map<String, dynamic> map) {
    return BudgetDebtPlan(
      debtId: map['debtId'] as String,
      plannedAmount:
          ((map['plannedAmount'] ?? map['amount']) as num?)?.toDouble() ?? 0.0,
      note: map['note'] as String?,
    );
  }
}

class Budget {
  final String id;
  final String periodType;
  final DateTime startDate;
  final DateTime endDate;
  final List<BudgetCategoryPlan> categories;
  final List<BudgetDebtPlan> plannedDebts;

  const Budget({
    required this.id,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.categories,
    required this.plannedDebts,
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
      plannedDebts: (json["plannedDebts"] as List<dynamic>? ?? [])
          .map((item) => BudgetDebtPlan.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

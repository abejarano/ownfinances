class ReportRange {
  final DateTime start;
  final DateTime end;

  const ReportRange({required this.start, required this.end});

  factory ReportRange.fromJson(Map<String, dynamic> json) {
    return ReportRange(
      start: DateTime.parse(json["start"] as String),
      end: DateTime.parse(json["end"] as String),
    );
  }
}

class ReportTotals {
  final double plannedIncome;
  final double plannedExpense;
  final double plannedNet;
  final double actualIncome;
  final double actualExpense;
  final double actualNet;
  final double remainingIncome;
  final double remainingExpense;
  final double remainingNet;

  const ReportTotals({
    required this.plannedIncome,
    required this.plannedExpense,
    required this.plannedNet,
    required this.actualIncome,
    required this.actualExpense,
    required this.actualNet,
    required this.remainingIncome,
    required this.remainingExpense,
    required this.remainingNet,
  });

  factory ReportTotals.fromJson(Map<String, dynamic> json) {
    return ReportTotals(
      plannedIncome: (json["plannedIncome"] as num?)?.toDouble() ?? 0,
      plannedExpense: (json["plannedExpense"] as num?)?.toDouble() ?? 0,
      plannedNet: (json["plannedNet"] as num?)?.toDouble() ?? 0,
      actualIncome: (json["actualIncome"] as num?)?.toDouble() ?? 0,
      actualExpense: (json["actualExpense"] as num?)?.toDouble() ?? 0,
      actualNet: (json["actualNet"] as num?)?.toDouble() ?? 0,
      remainingIncome: (json["remainingIncome"] as num?)?.toDouble() ?? 0,
      remainingExpense: (json["remainingExpense"] as num?)?.toDouble() ?? 0,
      remainingNet: (json["remainingNet"] as num?)?.toDouble() ?? 0,
    );
  }
}

class CategorySummary {
  final String categoryId;
  final String kind;
  final double planned;
  final double actual;
  final Map<String, double> actualByCurrency;
  final double remaining;
  final double progressPct;

  const CategorySummary({
    required this.categoryId,
    required this.kind,
    required this.planned,
    required this.actual,
    required this.actualByCurrency,
    required this.remaining,
    required this.progressPct,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    final actualByCurrencyRaw =
        json["actualByCurrency"] as Map<String, dynamic>? ?? {};
    return CategorySummary(
      categoryId: json["categoryId"] as String,
      kind: json["kind"] as String,
      planned: (json["planned"] as num?)?.toDouble() ?? 0,
      actual: (json["actual"] as num?)?.toDouble() ?? 0,
      actualByCurrency: actualByCurrencyRaw.map(
        (key, value) =>
            MapEntry(key, (value as num?)?.toDouble() ?? 0.0),
      ),
      remaining: (json["remaining"] as num?)?.toDouble() ?? 0,
      progressPct: (json["progressPct"] as num?)?.toDouble() ?? 0,
    );
  }
}

class ReportSummary {
  final ReportRange range;
  final ReportTotals totals;
  final List<CategorySummary> byCategory;
  final List<String> overspentCategories;
  final bool isDeficitVsPlan;

  const ReportSummary({
    required this.range,
    required this.totals,
    required this.byCategory,
    required this.overspentCategories,
    required this.isDeficitVsPlan,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    final flags = json["flags"] as Map<String, dynamic>? ?? {};
    return ReportSummary(
      range: ReportRange.fromJson(json["range"] as Map<String, dynamic>),
      totals: ReportTotals.fromJson(json["totals"] as Map<String, dynamic>),
      byCategory: (json["byCategory"] as List<dynamic>? ?? [])
          .map((item) => CategorySummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      overspentCategories:
          (flags["overspentCategories"] as List<dynamic>? ?? [])
              .map((item) => item.toString())
              .toList(),
      isDeficitVsPlan: flags["isDeficitVsPlan"] as bool? ?? false,
    );
  }
}

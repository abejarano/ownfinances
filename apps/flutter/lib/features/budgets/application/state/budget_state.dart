import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";

class BudgetState {
  final bool isLoading;
  final Budget? budget;
  final ReportRange? range;
  final Map<String, double> plannedByCategory;
  final Map<String, double> plannedByDebt;
  final String? error;

  const BudgetState({
    required this.isLoading,
    required this.budget,
    required this.range,
    required this.plannedByCategory,
    required this.plannedByDebt,
    this.error,
  });

  BudgetState copyWith({
    bool? isLoading,
    Budget? budget,
    ReportRange? range,
    Map<String, double>? plannedByCategory,
    Map<String, double>? plannedByDebt,
    String? error,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      budget: budget ?? this.budget,
      range: range ?? this.range,
      plannedByCategory: plannedByCategory ?? this.plannedByCategory,
      plannedByDebt: plannedByDebt ?? this.plannedByDebt,
      error: error,
    );
  }

  static const initial = BudgetState(
    isLoading: false,
    budget: null,
    range: null,
    plannedByCategory: {},
    plannedByDebt: {},
  );
}

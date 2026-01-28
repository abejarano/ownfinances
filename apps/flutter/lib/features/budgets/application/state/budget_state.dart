import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";

class BudgetSnapshot {
  final List<BudgetCategoryPlan> categories;
  final Map<String, double> plannedByDebt;

  const BudgetSnapshot({
    required this.categories,
    required this.plannedByDebt,
  });
}

class BudgetState {
  final bool isLoading;
  final Budget? budget;
  final ReportRange? range;
  final List<BudgetCategoryPlan> planCategories;
  final Map<String, double> plannedByDebt;
  final BudgetSnapshot? snapshot;
  final bool snapshotDismissed;
  final bool hasChanges;
  final String? error;

  const BudgetState({
    required this.isLoading,
    required this.budget,
    required this.range,
    required this.planCategories,
    required this.plannedByDebt,
    required this.snapshot,
    required this.snapshotDismissed,
    required this.hasChanges,
    this.error,
  });

  BudgetState copyWith({
    bool? isLoading,
    Budget? budget,
    ReportRange? range,
    List<BudgetCategoryPlan>? planCategories,
    Map<String, double>? plannedByDebt,
    BudgetSnapshot? snapshot,
    bool overwriteSnapshot = false,
    bool? snapshotDismissed,
    bool? hasChanges,
    String? error,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      budget: budget ?? this.budget,
      range: range ?? this.range,
      planCategories: planCategories ?? this.planCategories,
      plannedByDebt: plannedByDebt ?? this.plannedByDebt,
      snapshot: overwriteSnapshot ? snapshot : (snapshot ?? this.snapshot),
      snapshotDismissed: snapshotDismissed ?? this.snapshotDismissed,
      hasChanges: hasChanges ?? this.hasChanges,
      error: error,
    );
  }

  static const initial = BudgetState(
    isLoading: false,
    budget: null,
    range: null,
    planCategories: [],
    plannedByDebt: {},
    snapshot: null,
    snapshotDismissed: false,
    hasChanges: false,
  );
}

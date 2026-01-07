import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";

class CurrentBudget {
  final Budget? budget;
  final ReportRange range;

  const CurrentBudget({required this.budget, required this.range});
}

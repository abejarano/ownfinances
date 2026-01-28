import "package:ownfinances/features/budgets/data/datasources/budget_remote_data_source.dart";
import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/budgets/domain/entities/current_budget.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";

class BudgetRepository {
  final BudgetRemoteDataSource remote;

  BudgetRepository(this.remote);

  Future<CurrentBudget> current({
    required String period,
    required DateTime date,
  }) async {
    final payload = await remote.current(period: period, date: date);
    final budgetRaw = payload["budget"];
    final range = ReportRange.fromJson(
      payload["range"] as Map<String, dynamic>,
    );
    if (budgetRaw == null) {
      return CurrentBudget(budget: null, range: range);
    }
    return CurrentBudget(
      budget: Budget.fromJson(budgetRaw as Map<String, dynamic>),
      range: range,
    );
  }

  Future<Budget> save({
    String? id,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetCategoryPlan> categories,
    required List<BudgetDebtPayment> debtPayments,
  }) async {
    final payload = id == null
        ? await remote.create(
            period: period,
            startDate: startDate,
            endDate: endDate,
            categories: categories,
            debtPayments: debtPayments,
          )
        : await remote.update(
            id,
            categories: categories,
            debtPayments: debtPayments,
          );
    return Budget.fromJson(payload);
  }
}

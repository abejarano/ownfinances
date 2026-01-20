import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/budgets/domain/entities/current_budget.dart";

abstract class BudgetRepository {
  Future<CurrentBudget> current({
    required String period,
    required DateTime date,
  });

  Future<Budget> save({
    String? id,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLine> lines,
  });

  Future<Budget> removeLine({
    required String period,
    required DateTime date,
    required String categoryId,
  });
}

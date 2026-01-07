import "package:ownfinances/features/budgets/domain/entities/current_budget.dart";
import "package:ownfinances/features/budgets/domain/repositories/budget_repository.dart";

class GetCurrentBudgetUseCase {
  final BudgetRepository repository;

  GetCurrentBudgetUseCase(this.repository);

  Future<CurrentBudget> execute({
    required String period,
    required DateTime date,
  }) {
    return repository.current(period: period, date: date);
  }
}

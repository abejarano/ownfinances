import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/budgets/domain/repositories/budget_repository.dart";

class SaveBudgetUseCase {
  final BudgetRepository repository;

  SaveBudgetUseCase(this.repository);

  Future<Budget> execute({
    String? id,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLine> lines,
  }) {
    return repository.save(
      id: id,
      period: period,
      startDate: startDate,
      endDate: endDate,
      lines: lines,
    );
  }
}

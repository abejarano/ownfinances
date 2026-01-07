import "package:ownfinances/features/debts/domain/entities/debt_summary.dart";
import "package:ownfinances/features/debts/domain/repositories/debt_repository.dart";

class GetDebtSummaryUseCase {
  final DebtRepository repository;

  GetDebtSummaryUseCase(this.repository);

  Future<DebtSummary> execute(String id) {
    return repository.summary(id);
  }
}

import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/features/debts/domain/repositories/debt_repository.dart";

class ListDebtsUseCase {
  final DebtRepository repository;

  ListDebtsUseCase(this.repository);

  Future<List<Debt>> execute() {
    return repository.list();
  }
}

import "package:ownfinances/features/debts/domain/repositories/debt_repository.dart";

class DeleteDebtUseCase {
  final DebtRepository repository;

  DeleteDebtUseCase(this.repository);

  Future<void> execute(String id) {
    return repository.delete(id);
  }
}

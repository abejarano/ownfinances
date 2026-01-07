import "package:ownfinances/features/debts/domain/entities/debt_transaction.dart";
import "package:ownfinances/features/debts/domain/repositories/debt_transaction_repository.dart";

class CreateDebtTransactionUseCase {
  final DebtTransactionRepository repository;

  CreateDebtTransactionUseCase(this.repository);

  Future<DebtTransaction> execute({
    required String debtId,
    required DateTime date,
    required String type,
    required double amount,
    String? accountId,
    String? note,
  }) {
    return repository.create(
      debtId: debtId,
      date: date,
      type: type,
      amount: amount,
      accountId: accountId,
      note: note,
    );
  }
}

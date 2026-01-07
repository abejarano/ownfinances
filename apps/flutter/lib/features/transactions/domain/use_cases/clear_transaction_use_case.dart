import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";

class ClearTransactionUseCase {
  final TransactionRepository repository;

  ClearTransactionUseCase(this.repository);

  Future<Transaction> execute(String id) {
    return repository.clear(id);
  }
}

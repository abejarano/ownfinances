import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";

class RestoreTransactionUseCase {
  final TransactionRepository repository;

  RestoreTransactionUseCase(this.repository);

  Future<Transaction> execute(String id) {
    return repository.restore(id);
  }
}

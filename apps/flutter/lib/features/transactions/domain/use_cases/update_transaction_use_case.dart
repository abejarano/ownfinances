import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";

class UpdateTransactionUseCase {
  final TransactionRepository repository;

  UpdateTransactionUseCase(this.repository);

  Future<Transaction> execute(String id, Map<String, dynamic> payload) {
    return repository.update(id, payload);
  }
}

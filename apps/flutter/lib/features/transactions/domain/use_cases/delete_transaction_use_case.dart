import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";

class DeleteTransactionUseCase {
  final TransactionRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<void> execute(String id) {
    return repository.delete(id);
  }
}

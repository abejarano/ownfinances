import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";

class ListTransactionsUseCase {
  final TransactionRepository repository;

  ListTransactionsUseCase(this.repository);

  Future<Paginated<Transaction>> execute({TransactionFilters? filters}) {
    return repository.list(filters: filters);
  }
}

import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";

class TransactionFilters {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? categoryId;
  final String? accountId;
  final String? type;
  final String? status;
  final String? query;

  const TransactionFilters({
    this.dateFrom,
    this.dateTo,
    this.categoryId,
    this.accountId,
    this.type,
    this.status,
    this.query,
  });
}

abstract class TransactionRepository {
  Future<Paginated<Transaction>> list({TransactionFilters? filters});

  Future<Transaction> create(Map<String, dynamic> payload);

  Future<Transaction> update(String id, Map<String, dynamic> payload);

  Future<void> delete(String id);

  Future<Transaction> clear(String id);

  Future<Transaction> restore(String id);
}

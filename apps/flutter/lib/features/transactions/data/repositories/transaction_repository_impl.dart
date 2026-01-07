import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/transactions/data/datasources/transaction_remote_data_source.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remote;

  TransactionRepositoryImpl(this.remote);

  @override
  Future<Paginated<Transaction>> list({TransactionFilters? filters}) async {
    final payload = await remote.list(filters: filters);
    final results = (payload["results"] as List<dynamic>? ?? [])
        .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
        .toList();
    return Paginated(
      nextPage: payload["nextPag"] as int?,
      count: payload["count"] as int? ?? results.length,
      results: results,
    );
  }

  @override
  Future<Transaction> create(Map<String, dynamic> payload) async {
    final result = await remote.create(payload);
    return Transaction.fromJson(result);
  }

  @override
  Future<Transaction> update(String id, Map<String, dynamic> payload) async {
    final result = await remote.update(id, payload);
    return Transaction.fromJson(result);
  }

  @override
  Future<void> delete(String id) {
    return remote.delete(id);
  }

  @override
  Future<Transaction> clear(String id) async {
    final result = await remote.clear(id);
    return Transaction.fromJson(result);
  }

  @override
  Future<Transaction> restore(String id) async {
    final result = await remote.restore(id);
    return Transaction.fromJson(result);
  }
}

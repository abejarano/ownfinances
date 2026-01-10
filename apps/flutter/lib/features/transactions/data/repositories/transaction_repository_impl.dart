import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/transactions/data/datasources/transaction_remote_data_source.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_delete_response.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_write_response.dart";
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

  @override
  Future<TransactionWriteResponse> createWithImpact({
    required Map<String, dynamic> payload,
    required String period,
  }) async {
    final result = await remote.createWithImpact(payload, period: period);
    return TransactionWriteResponse.fromJson(result);
  }

  @override
  Future<TransactionWriteResponse> updateWithImpact({
    required String id,
    required Map<String, dynamic> payload,
    required String period,
  }) async {
    final result = await remote.updateWithImpact(id, payload, period: period);
    return TransactionWriteResponse.fromJson(result);
  }

  @override
  Future<TransactionWriteResponse> clearWithImpact({
    required String id,
    required String period,
  }) async {
    final result = await remote.clearWithImpact(id, period: period);
    return TransactionWriteResponse.fromJson(result);
  }

  @override
  Future<TransactionWriteResponse> restoreWithImpact({
    required String id,
    required String period,
  }) async {
    final result = await remote.restoreWithImpact(id, period: period);
    return TransactionWriteResponse.fromJson(result);
  }

  @override
  Future<TransactionDeleteResponse> deleteWithImpact({
    required String id,
    required String period,
  }) async {
    final result = await remote.deleteWithImpact(id, period: period);
    return TransactionDeleteResponse.fromJson(result);
  }

  @override
  Future<List<Transaction>> listPending({
    String? month,
    String? categoryId,
    String? recurringRuleId,
  }) async {
    final payload = await remote.listPending(
      month: month,
      categoryId: categoryId,
      recurringRuleId: recurringRuleId,
    );
    final results = (payload["results"] as List<dynamic>? ?? [])
        .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
        .toList();
    return results;
  }

  @override
  Future<int> confirmBatch(List<String> transactionIds) async {
    final result = await remote.confirmBatch(transactionIds);
    return result["confirmed"] as int? ?? 0;
  }
}

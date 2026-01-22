import "package:ownfinances/features/transactions/domain/entities/transaction_filters.dart";
import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/transactions/data/datasources/transaction_remote_data_source.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_delete_response.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_write_response.dart";

class TransactionRepository {
  final TransactionRemoteDataSource remote;

  TransactionRepository(this.remote);

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

  Future<Transaction> create(Map<String, dynamic> payload) async {
    final result = await remote.create(payload);
    return Transaction.fromJson(result);
  }

  Future<Transaction> update(String id, Map<String, dynamic> payload) async {
    final result = await remote.update(id, payload);
    return Transaction.fromJson(result);
  }

  Future<void> delete(String id) {
    return remote.delete(id);
  }

  Future<Transaction> clear(String id) async {
    final result = await remote.clear(id);
    return Transaction.fromJson(result);
  }

  Future<Transaction> restore(String id) async {
    final result = await remote.restore(id);
    return Transaction.fromJson(result);
  }

  Future<TransactionWriteResponse> createWithImpact({
    required Map<String, dynamic> payload,
    required String period,
  }) async {
    final result = await remote.createWithImpact(payload, period: period);
    return TransactionWriteResponse.fromJson(result);
  }

  Future<TransactionWriteResponse> updateWithImpact({
    required String id,
    required Map<String, dynamic> payload,
    required String period,
  }) async {
    final result = await remote.updateWithImpact(id, payload, period: period);
    return TransactionWriteResponse.fromJson(result);
  }

  Future<TransactionWriteResponse> clearWithImpact({
    required String id,
    required String period,
  }) async {
    final result = await remote.clearWithImpact(id, period: period);
    return TransactionWriteResponse.fromJson(result);
  }

  Future<TransactionWriteResponse> restoreWithImpact({
    required String id,
    required String period,
  }) async {
    final result = await remote.restoreWithImpact(id, period: period);
    return TransactionWriteResponse.fromJson(result);
  }

  Future<TransactionDeleteResponse> deleteWithImpact({
    required String id,
    required String period,
  }) async {
    final result = await remote.deleteWithImpact(id, period: period);
    return TransactionDeleteResponse.fromJson(result);
  }

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

  Future<int> confirmBatch(List<String> transactionIds) async {
    final result = await remote.confirmBatch(transactionIds);
    return result["confirmed"] as int? ?? 0;
  }
}

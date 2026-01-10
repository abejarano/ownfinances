import "package:ownfinances/core/models/paginated.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_delete_response.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_write_response.dart";

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

  TransactionFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? categoryId,
    String? accountId,
    String? type,
    String? status,
    String? query,
  }) {
    return TransactionFilters(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      status: status ?? this.status,
      query: query ?? this.query,
    );
  }
}

abstract class TransactionRepository {
  Future<Paginated<Transaction>> list({TransactionFilters? filters});

  Future<Transaction> create(Map<String, dynamic> payload);

  Future<Transaction> update(String id, Map<String, dynamic> payload);

  Future<void> delete(String id);

  Future<Transaction> clear(String id);

  Future<Transaction> restore(String id);

  Future<TransactionWriteResponse> createWithImpact({
    required Map<String, dynamic> payload,
    required String period,
  });

  Future<TransactionWriteResponse> updateWithImpact({
    required String id,
    required Map<String, dynamic> payload,
    required String period,
  });

  Future<TransactionWriteResponse> clearWithImpact({
    required String id,
    required String period,
  });

  Future<TransactionWriteResponse> restoreWithImpact({
    required String id,
    required String period,
  });

  Future<TransactionDeleteResponse> deleteWithImpact({
    required String id,
    required String period,
  });

  Future<List<Transaction>> listPending({
    String? month,
    String? categoryId,
    String? recurringRuleId,
  });

  Future<int> confirmBatch(List<String> transactionIds);
}

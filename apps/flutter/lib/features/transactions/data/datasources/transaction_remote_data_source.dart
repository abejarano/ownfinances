import "package:ownfinances/features/transactions/domain/entities/transaction_filters.dart";
import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/transactions/data/repositories/transaction_repository.dart";

class TransactionRemoteDataSource {
  final ApiClient apiClient;

  TransactionRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> list({TransactionFilters? filters}) async {
    final safe = filters;
    final response = await apiClient.get(
      "/transactions",
      query: {
        if (safe != null && safe.dateFrom != null)
          "dateFrom": safe.dateFrom!.toIso8601String(),
        if (safe != null && safe.dateTo != null)
          "dateTo": safe.dateTo!.toIso8601String(),
        if (safe != null && safe.categoryId != null)
          "categoryId": safe.categoryId!,
        if (safe != null && safe.accountId != null)
          "accountId": safe.accountId!,
        if (safe != null && safe.type != null) "type": safe.type!,
        if (safe != null && safe.status != null) "status": safe.status!,
        if (safe != null && safe.query != null && safe.query!.isNotEmpty)
          "q": safe.query!,
        "limit": (safe != null && safe.limit != null)
            ? safe.limit.toString()
            : "50",
        "page": "1",
        "sort": "-date",
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await apiClient.post("/transactions", payload);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await apiClient.put("/transactions/$id", payload);
    return response as Map<String, dynamic>;
  }

  Future<void> delete(String id) async {
    await apiClient.delete("/transactions/$id");
  }

  Future<Map<String, dynamic>> clear(String id) async {
    final response = await apiClient.post("/transactions/$id/clear", {});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> restore(String id) async {
    final response = await apiClient.post("/transactions/$id/restore", {});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createWithImpact(
    Map<String, dynamic> payload, {
    required String period,
  }) async {
    final response = await apiClient.post(
      "/transactions",
      payload,
      query: {"includeImpact": "true", "period": period},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateWithImpact(
    String id,
    Map<String, dynamic> payload, {
    required String period,
  }) async {
    final response = await apiClient.put(
      "/transactions/$id",
      payload,
      query: {"includeImpact": "true", "period": period},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> clearWithImpact(
    String id, {
    required String period,
  }) async {
    final response = await apiClient.post(
      "/transactions/$id/clear",
      {},
      query: {"includeImpact": "true", "period": period},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> restoreWithImpact(
    String id, {
    required String period,
  }) async {
    final response = await apiClient.post(
      "/transactions/$id/restore",
      {},
      query: {"includeImpact": "true", "period": period},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteWithImpact(
    String id, {
    required String period,
  }) async {
    final response = await apiClient.delete(
      "/transactions/$id",
      query: {"includeImpact": "true", "period": period},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listPending({
    String? month,
    String? categoryId,
    String? recurringRuleId,
  }) async {
    final response = await apiClient.get(
      "/transactions/pending",
      query: {
        if (month != null) "month": month,
        if (categoryId != null) "categoryId": categoryId,
        if (recurringRuleId != null) "recurringRuleId": recurringRuleId,
        "limit": "100",
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmBatch(List<String> transactionIds) async {
    final response = await apiClient.post("/transactions/confirm-batch", {
      "transactionIds": transactionIds,
    });
    return response as Map<String, dynamic>;
  }
}

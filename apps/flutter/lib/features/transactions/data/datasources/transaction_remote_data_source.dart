import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";

class TransactionRemoteDataSource {
  final ApiClient apiClient;

  TransactionRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> list({TransactionFilters? filters}) {
    final safe = filters;
    return apiClient.get(
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
        "limit": "50",
        "page": "1",
        "sort": "-date",
      },
    );
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) {
    return apiClient.post("/transactions", payload);
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> payload) {
    return apiClient.put("/transactions/$id", payload);
  }

  Future<void> delete(String id) async {
    await apiClient.delete("/transactions/$id");
  }

  Future<Map<String, dynamic>> clear(String id) {
    return apiClient.post("/transactions/$id/clear", {});
  }

  Future<Map<String, dynamic>> restore(String id) {
    return apiClient.post("/transactions/$id/restore", {});
  }

  Future<Map<String, dynamic>> createWithImpact(
    Map<String, dynamic> payload, {
    required String period,
  }) {
    return apiClient.post(
      "/transactions",
      payload,
      query: {"includeImpact": "true", "period": period},
    );
  }

  Future<Map<String, dynamic>> updateWithImpact(
    String id,
    Map<String, dynamic> payload, {
    required String period,
  }) {
    return apiClient.put(
      "/transactions/$id",
      payload,
      query: {"includeImpact": "true", "period": period},
    );
  }

  Future<Map<String, dynamic>> clearWithImpact(
    String id, {
    required String period,
  }) {
    return apiClient.post(
      "/transactions/$id/clear",
      {},
      query: {"includeImpact": "true", "period": period},
    );
  }

  Future<Map<String, dynamic>> restoreWithImpact(
    String id, {
    required String period,
  }) {
    return apiClient.post(
      "/transactions/$id/restore",
      {},
      query: {"includeImpact": "true", "period": period},
    );
  }

  Future<Map<String, dynamic>> deleteWithImpact(
    String id, {
    required String period,
  }) {
    return apiClient.delete(
      "/transactions/$id",
      query: {"includeImpact": "true", "period": period},
    );
  }

  Future<Map<String, dynamic>> listPending({
    String? month,
    String? categoryId,
    String? recurringRuleId,
  }) {
    return apiClient.get(
      "/transactions/pending",
      query: {
        if (month != null) "month": month,
        if (categoryId != null) "categoryId": categoryId,
        if (recurringRuleId != null) "recurringRuleId": recurringRuleId,
        "limit": "100",
      },
    );
  }

  Future<Map<String, dynamic>> confirmBatch(List<String> transactionIds) {
    return apiClient.post(
      "/transactions/confirm-batch",
      {"transactionIds": transactionIds},
    );
  }
}

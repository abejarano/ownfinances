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
}

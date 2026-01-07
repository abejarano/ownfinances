import "package:ownfinances/core/infrastructure/api/api_client.dart";

class DebtTransactionRemoteDataSource {
  final ApiClient apiClient;

  DebtTransactionRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) {
    return apiClient.post("/debt_transactions", payload);
  }
}

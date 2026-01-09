import "package:ownfinances/core/infrastructure/api/api_client.dart";

class DebtRemoteDataSource {
  final ApiClient apiClient;

  DebtRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> list() {
    return apiClient.get("/debts", query: {"limit": "100"});
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) {
    return apiClient.post("/debts", payload);
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> payload) {
    return apiClient.put("/debts/$id", payload);
  }

  Future<void> delete(String id) {
    return apiClient.delete("/debts/$id");
  }

  Future<Map<String, dynamic>> summary(String id) {
    return apiClient.get("/debts/$id/summary");
  }

  Future<Map<String, dynamic>> history(String id, {String? month}) {
    final query = month != null ? {"month": month} : <String, String>{};
    return apiClient.get("/debts/$id/history", query: query);
  }
}

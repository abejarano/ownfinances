import "package:ownfinances/core/infrastructure/api/api_client.dart";

class DebtRemoteDataSource {
  final ApiClient apiClient;

  DebtRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> list() async {
    final response = await apiClient.get("/debts", query: {"limit": "100"});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await apiClient.post("/debts", payload);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await apiClient.put("/debts/$id", payload);
    return response as Map<String, dynamic>;
  }

  Future<void> delete(String id) {
    return apiClient.delete("/debts/$id");
  }

  Future<Map<String, dynamic>> summary(String id) async {
    final response = await apiClient.get("/debts/$id/summary");
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> history(String id, {String? month}) async {
    final query = month != null ? {"month": month} : <String, String>{};
    final response = await apiClient.get("/debts/$id/history", query: query);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOverview() async {
    final response = await apiClient.get("/debts/overview");
    return response as Map<String, dynamic>;
  }
}

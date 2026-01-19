import "package:ownfinances/core/infrastructure/api/api_client.dart";

class GoalRemoteDataSource {
  final ApiClient apiClient;

  GoalRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> list() async {
    final response = await apiClient.get("/goals", query: {"limit": "100"});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await apiClient.post("/goals", payload);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await apiClient.put("/goals/$id", payload);
    return response as Map<String, dynamic>;
  }

  Future<void> delete(String id) {
    return apiClient.delete("/goals/$id");
  }

  Future<Map<String, dynamic>> projection(String id) async {
    final response = await apiClient.get("/goals/$id/projection");
    return response as Map<String, dynamic>;
  }

  Future<void> createContribution(String id, Map<String, dynamic> payload) {
    return apiClient.post("/goals/$id/contributions", payload);
  }
}

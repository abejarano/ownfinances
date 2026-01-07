import "package:ownfinances/core/infrastructure/api/api_client.dart";

class GoalRemoteDataSource {
  final ApiClient apiClient;

  GoalRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> list() {
    return apiClient.get("/goals", query: {"limit": "100"});
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) {
    return apiClient.post("/goals", payload);
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> payload) {
    return apiClient.put("/goals/$id", payload);
  }

  Future<void> delete(String id) {
    return apiClient.delete("/goals/$id");
  }

  Future<Map<String, dynamic>> projection(String id) {
    return apiClient.get("/goals/$id/projection");
  }

  Future<void> createContribution(String id, Map<String, dynamic> payload) {
    return apiClient.post("/goals/$id/contributions", payload);
  }
}

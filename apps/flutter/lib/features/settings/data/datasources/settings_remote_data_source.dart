import "package:ownfinances/core/infrastructure/api/api_client.dart";

class SettingsRemoteDataSource {
  final ApiClient apiClient;

  SettingsRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> fetch() async {
    final response = await apiClient.get("/settings");
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {};
  }

  Future<Map<String, dynamic>> update(Map<String, dynamic> payload) async {
    final response = await apiClient.put("/settings", payload);
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {};
  }
}

import "package:ownfinances/core/infrastructure/api/api_client.dart";

class CountryRemoteDataSource {
  final ApiClient apiClient;

  CountryRemoteDataSource(this.apiClient);

  Future<List<dynamic>> list() async {
    final response = await apiClient.get("/countries");
    if (response is Map && response.containsKey("results")) {
      return response["results"] as List<dynamic>;
    }
    return [];
  }
}

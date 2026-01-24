import "package:ownfinances/core/infrastructure/api/api_client.dart";

class BankRemoteDataSource {
  final ApiClient apiClient;

  BankRemoteDataSource(this.apiClient);

  Future<List<dynamic>> list({String? country}) async {
    final response = await apiClient.get(
      "/banks",
      query: {if (country != null) "country": country},
    );
    // Assuming backend returns { results: [], count: N }
    if (response is Map && response.containsKey('results')) {
      return response['results'] as List<dynamic>;
    }
    return [];
  }
}

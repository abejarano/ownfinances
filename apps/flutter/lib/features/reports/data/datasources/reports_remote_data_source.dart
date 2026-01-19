import "package:ownfinances/core/infrastructure/api/api_client.dart";

class ReportsRemoteDataSource {
  final ApiClient apiClient;

  ReportsRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> summary({
    required String period,
    required DateTime date,
  }) async {
    final response = await apiClient.get(
      "/reports/summary",
      query: {"period": period, "date": date.toIso8601String()},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> balances({
    required String period,
    required DateTime date,
  }) async {
    final response = await apiClient.get(
      "/reports/balances",
      query: {"period": period, "date": date.toIso8601String()},
    );
    return response as Map<String, dynamic>;
  }
}

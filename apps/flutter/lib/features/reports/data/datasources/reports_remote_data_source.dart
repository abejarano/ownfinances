import "package:ownfinances/core/infrastructure/api/api_client.dart";

class ReportsRemoteDataSource {
  final ApiClient apiClient;

  ReportsRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> summary({
    required String period,
    required DateTime date,
  }) {
    return apiClient.get(
      "/reports/summary",
      query: {"period": period, "date": date.toIso8601String()},
    );
  }

  Future<Map<String, dynamic>> balances({
    required String period,
    required DateTime date,
  }) {
    return apiClient.get(
      "/reports/balances",
      query: {"period": period, "date": date.toIso8601String()},
    );
  }
}

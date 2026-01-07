import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/budgets/domain/entities/budget.dart";

class BudgetRemoteDataSource {
  final ApiClient apiClient;

  BudgetRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> current({
    required String period,
    required DateTime date,
  }) {
    return apiClient.get(
      "/budgets/current",
      query: {"period": period, "date": date.toIso8601String()},
    );
  }

  Future<Map<String, dynamic>> create({
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLine> lines,
  }) {
    return apiClient.post("/budgets", {
      "periodType": period,
      "startDate": startDate.toIso8601String(),
      "endDate": endDate.toIso8601String(),
      "lines": lines.map((line) => line.toJson()).toList(),
    });
  }

  Future<Map<String, dynamic>> update(
    String id, {
    required List<BudgetLine> lines,
  }) {
    return apiClient.put("/budgets/$id", {
      "lines": lines.map((line) => line.toJson()).toList(),
    });
  }
}

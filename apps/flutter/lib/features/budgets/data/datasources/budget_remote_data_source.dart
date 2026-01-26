import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/budgets/domain/entities/budget.dart";

class BudgetRemoteDataSource {
  final ApiClient apiClient;

  BudgetRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> current({
    required String period,
    required DateTime date,
  }) async {
    final response = await apiClient.get(
      "/budgets/current",
      query: {"period": period, "date": date.toIso8601String()},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create({
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLine> lines,
    required List<BudgetDebtPayment> debtPayments,
  }) async {
    final response = await apiClient.post("/budgets", {
      "periodType": period,
      "startDate": startDate.toIso8601String(),
      "endDate": endDate.toIso8601String(),
      "lines": lines.map((line) => line.toJson()).toList(),
      "debtPayments": debtPayments.map((line) => line.toJson()).toList(),
    });
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    String id, {
    required List<BudgetLine> lines,
    required List<BudgetDebtPayment> debtPayments,
  }) async {
    final response = await apiClient.put("/budgets/$id", {
      "lines": lines.map((line) => line.toJson()).toList(),
      "debtPayments": debtPayments.map((line) => line.toJson()).toList(),
    });
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeLine({
    required String period,
    required DateTime date,
    required String categoryId,
  }) async {
    final response = await apiClient.delete(
      "/budgets/current/lines/$categoryId",
      query: {"period": period, "date": date.toIso8601String()},
    );
    return response as Map<String, dynamic>;
  }
}

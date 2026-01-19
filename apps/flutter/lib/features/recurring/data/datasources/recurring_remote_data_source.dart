import 'package:ownfinances/core/infrastructure/api/api_client.dart';

class RecurringRemoteDataSource {
  final ApiClient apiClient;

  RecurringRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> list() async {
    final response = await apiClient.get(
      '/recurring_rules',
      query: {'limit': '100'},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await apiClient.post('/recurring_rules', payload);
    return response as Map<String, dynamic>;
  }

  Future<void> delete(String id) {
    return apiClient.delete('/recurring_rules/$id');
  }

  Future<dynamic> preview(String period, DateTime date) {
    final month = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    return apiClient.get(
      '/recurring_rules/preview',
      query: {
        'period': period,
        'month': month, // YYYY-MM
      },
    );
  }

  Future<Map<String, dynamic>> run(String period, DateTime date) async {
    final month = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    final response = await apiClient.post('/recurring_rules/run', {
      'period': period,
      'month': month, // YYYY-MM
    });
    return response as Map<String, dynamic>;
  }

  Future<void> materialize(String ruleId, DateTime date) {
    return apiClient.post('/recurring_rules/$ruleId/materialize', {
      'date': date.toIso8601String(),
    });
  }

  Future<void> split(
    String ruleId,
    DateTime date,
    Map<String, dynamic> template,
  ) {
    return apiClient.post('/recurring_rules/$ruleId/split', {
      'date': date.toIso8601String(),
      'template': template,
    });
  }

  Future<Map<String, dynamic>> getPendingSummary() async {
    final response = await apiClient.get('/recurring_rules/pending-summary');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCatchupSummary() async {
    final response = await apiClient.get('/recurring_rules/catchup');
    return response as Map<String, dynamic>;
  }

  Future<void> ignore(String ruleId, DateTime date) {
    return apiClient.post('/recurring_rules/$ruleId/ignore', {
      'date': date.toIso8601String(),
    });
  }

  Future<void> undoIgnore(String ruleId, DateTime date) {
    return apiClient.post('/recurring_rules/$ruleId/undo-ignore', {
      'date': date.toIso8601String(),
    });
  }
}

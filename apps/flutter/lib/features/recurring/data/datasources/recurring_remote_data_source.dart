import 'package:ownfinances/core/infrastructure/api/api_client.dart';

class RecurringRemoteDataSource {
  final ApiClient apiClient;

  RecurringRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> list() {
    return apiClient.get('/recurring_rules', query: {'limit': '100'});
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) {
    return apiClient.post('/recurring_rules', payload);
  }

  Future<void> delete(String id) {
    return apiClient.delete('/recurring_rules/$id');
  }

  Future<dynamic> preview(String period, DateTime date) {
    return apiClient.get(
      '/recurring_rules/preview',
      query: {
        'period': period,
        'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
      },
    );
  }

  Future<Map<String, dynamic>> run(String period, DateTime date) {
    return apiClient.post('/recurring_rules/run', {
      'period': period,
      'date': date.toIso8601String().split('T')[0],
    });
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
}

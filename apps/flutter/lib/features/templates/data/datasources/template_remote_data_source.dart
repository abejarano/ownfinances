import 'package:ownfinances/core/infrastructure/api/api_client.dart';

class TemplateRemoteDataSource {
  final ApiClient _client;

  TemplateRemoteDataSource(this._client);

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await _client.post('/templates', payload);
    return response;
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _client.put('/templates/$id', payload);
  }

  Future<void> delete(String id) async {
    await _client.delete('/templates/$id');
  }

  Future<Map<String, dynamic>> list() async {
    final response = await _client.get('/templates');
    return response; // Expecting { results: [], ... }
  }
}

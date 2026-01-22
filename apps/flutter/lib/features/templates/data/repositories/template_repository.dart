import 'package:ownfinances/features/templates/data/datasources/template_remote_data_source.dart';
import 'package:ownfinances/features/templates/domain/entities/transaction_template.dart';

class TemplateRepository {
  final TemplateRemoteDataSource _remoteDataSource;

  TemplateRepository(this._remoteDataSource);

  Future<TransactionTemplate> create(Map<String, dynamic> payload) async {
    final result = await _remoteDataSource.create(payload);
    return TransactionTemplate.fromJson(result);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _remoteDataSource.update(id, payload);
  }

  Future<void> delete(String id) async {
    await _remoteDataSource.delete(id);
  }

  Future<List<TransactionTemplate>> list() async {
    final response = await _remoteDataSource.list();
    final results = response['results'] as List;
    return results.map((e) => TransactionTemplate.fromJson(e)).toList();
  }
}

import 'package:ownfinances/features/templates/data/datasources/template_remote_data_source.dart';
import 'package:ownfinances/features/templates/domain/entities/transaction_template.dart';
import 'package:ownfinances/features/templates/domain/repositories/template_repository.dart';

class TemplateRepositoryImpl implements TemplateRepository {
  final TemplateRemoteDataSource _remoteDataSource;

  TemplateRepositoryImpl(this._remoteDataSource);

  @override
  Future<TransactionTemplate> create(Map<String, dynamic> payload) async {
    final result = await _remoteDataSource.create(payload);
    return TransactionTemplate.fromJson(result);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> payload) async {
    await _remoteDataSource.update(id, payload);
  }

  @override
  Future<void> delete(String id) async {
    await _remoteDataSource.delete(id);
  }

  @override
  Future<List<TransactionTemplate>> list() async {
    final response = await _remoteDataSource.list();
    final results = response['results'] as List;
    return results.map((e) => TransactionTemplate.fromJson(e)).toList();
  }
}

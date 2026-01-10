import 'package:ownfinances/features/recurring/data/datasources/recurring_remote_data_source.dart';
import 'package:ownfinances/features/recurring/domain/entities/recurring_rule.dart';
import 'package:ownfinances/features/recurring/domain/repositories/recurring_repository.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  final RecurringRemoteDataSource _remoteDataSource;

  RecurringRepositoryImpl(this._remoteDataSource);

  @override
  Future<RecurringRule> create(Map<String, dynamic> payload) async {
    final result = await _remoteDataSource.create(payload);
    // Backend returns the created rule directly as JSON?
    // Usually it's raw JSON object.
    return RecurringRule.fromJson(result);
  }

  @override
  Future<void> delete(String id) {
    return _remoteDataSource.delete(id);
  }

  @override
  Future<List<RecurringRule>> list() async {
    final response = await _remoteDataSource.list();
    final results = response['results'] as List;
    return results.map((e) => RecurringRule.fromJson(e)).toList();
  }

  @override
  Future<List<RecurringPreviewItem>> preview(
    String period,
    DateTime date,
  ) async {
    final response = await _remoteDataSource.preview(period, date);
    // response is List<dynamic>
    final list = response as List;
    return list.map((e) => RecurringPreviewItem.fromJson(e)).toList();
  }

  @override
  Future<Map<String, dynamic>> run(String period, DateTime date) {
    return _remoteDataSource.run(period, date);
  }

  @override
  Future<void> materialize(String ruleId, DateTime date) {
    return _remoteDataSource.materialize(ruleId, date);
  }

  @override
  Future<void> split(
    String ruleId,
    DateTime date,
    Map<String, dynamic> template,
  ) {
    return _remoteDataSource.split(ruleId, date, template);
  }

  @override
  Future<Map<String, dynamic>> getPendingSummary() {
    return _remoteDataSource.getPendingSummary();
  }

  @override
  Future<Map<String, dynamic>> getCatchupSummary() {
    return _remoteDataSource.getCatchupSummary();
  }
}

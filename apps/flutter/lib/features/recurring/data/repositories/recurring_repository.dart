import 'package:ownfinances/features/recurring/data/datasources/recurring_remote_data_source.dart';
import 'package:ownfinances/features/recurring/domain/entities/recurring_rule.dart';

class RecurringRepository {
  final RecurringRemoteDataSource _remoteDataSource;

  RecurringRepository(this._remoteDataSource);

  Future<RecurringRule> create(Map<String, dynamic> payload) async {
    final result = await _remoteDataSource.create(payload);
    // Backend returns { "rule": {...} }
    // We check if "rule" key exists, otherwise assume root
    final data = result.containsKey('rule') ? result['rule'] : result;
    return RecurringRule.fromJson(data);
  }

  Future<void> delete(String id) {
    return _remoteDataSource.delete(id);
  }

  Future<List<RecurringRule>> list() async {
    final response = await _remoteDataSource.list();
    final results = response['results'] as List;
    return results.map((e) => RecurringRule.fromJson(e)).toList();
  }

  Future<List<RecurringPreviewItem>> preview(
    String period,
    DateTime date,
  ) async {
    final response = await _remoteDataSource.preview(period, date);
    // response is List<dynamic>
    final list = response as List;
    return list.map((e) => RecurringPreviewItem.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> run(String period, DateTime date) {
    return _remoteDataSource.run(period, date);
  }

  Future<void> materialize(String ruleId, DateTime date) {
    return _remoteDataSource.materialize(ruleId, date);
  }

  Future<void> split(
    String ruleId,
    DateTime date,
    Map<String, dynamic> template,
  ) {
    return _remoteDataSource.split(ruleId, date, template);
  }

  Future<Map<String, dynamic>> getPendingSummary() {
    return _remoteDataSource.getPendingSummary();
  }

  Future<Map<String, dynamic>> getCatchupSummary() {
    return _remoteDataSource.getCatchupSummary();
  }

  Future<void> ignore(String ruleId, DateTime date) {
    return _remoteDataSource.ignore(ruleId, date);
  }

  Future<void> undoIgnore(String ruleId, DateTime date) {
    return _remoteDataSource.undoIgnore(ruleId, date);
  }
}

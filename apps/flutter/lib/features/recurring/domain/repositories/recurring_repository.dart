import 'package:ownfinances/features/recurring/domain/entities/recurring_rule.dart';

abstract class RecurringRepository {
  Future<RecurringRule> create(Map<String, dynamic> payload);
  Future<List<RecurringRule>> list();
  Future<void> delete(String id);
  Future<List<RecurringPreviewItem>> preview(String period, DateTime date);
  Future<Map<String, dynamic>> run(String period, DateTime date);
  Future<void> materialize(String ruleId, DateTime date);
  Future<void> split(
    String ruleId,
    DateTime date,
    Map<String, dynamic> template,
  );
  Future<Map<String, dynamic>> getPendingSummary();
  Future<Map<String, dynamic>> getCatchupSummary();
}

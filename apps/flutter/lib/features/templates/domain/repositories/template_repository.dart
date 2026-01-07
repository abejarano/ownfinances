import 'package:ownfinances/features/templates/domain/entities/transaction_template.dart';

abstract class TemplateRepository {
  Future<TransactionTemplate> create(Map<String, dynamic> payload);
  Future<void> update(String id, Map<String, dynamic> payload);
  Future<void> delete(String id);
  Future<List<TransactionTemplate>> list();
}

import 'package:ownfinances/features/recurring/domain/entities/recurring_rule.dart';
import 'package:ownfinances/features/recurring/domain/repositories/recurring_repository.dart';

class PreviewRecurringRulesUseCase {
  final RecurringRepository _repository;

  PreviewRecurringRulesUseCase(this._repository);

  Future<List<RecurringPreviewItem>> call(String period, DateTime date) {
    return _repository.preview(period, date);
  }
}

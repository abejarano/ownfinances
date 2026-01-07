import 'package:ownfinances/features/recurring/domain/repositories/recurring_repository.dart';

class SplitRecurringRuleUseCase {
  final RecurringRepository _repository;

  SplitRecurringRuleUseCase(this._repository);

  Future<void> call(
    String ruleId,
    DateTime date,
    Map<String, dynamic> template,
  ) {
    return _repository.split(ruleId, date, template);
  }
}

import 'package:ownfinances/features/recurring/domain/entities/recurring_rule.dart';
import 'package:ownfinances/features/recurring/domain/repositories/recurring_repository.dart';

class CreateRecurringRuleUseCase {
  final RecurringRepository _repository;

  CreateRecurringRuleUseCase(this._repository);

  Future<RecurringRule> call(Map<String, dynamic> payload) {
    return _repository.create(payload);
  }
}

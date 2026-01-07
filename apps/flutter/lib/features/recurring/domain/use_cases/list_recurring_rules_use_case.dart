import 'package:ownfinances/features/recurring/domain/entities/recurring_rule.dart';
import 'package:ownfinances/features/recurring/domain/repositories/recurring_repository.dart';

class ListRecurringRulesUseCase {
  final RecurringRepository _repository;

  ListRecurringRulesUseCase(this._repository);

  Future<List<RecurringRule>> call() {
    return _repository.list();
  }
}

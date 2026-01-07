import 'package:ownfinances/features/recurring/domain/repositories/recurring_repository.dart';

class DeleteRecurringRuleUseCase {
  final RecurringRepository _repository;

  DeleteRecurringRuleUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.delete(id);
  }
}

import 'package:ownfinances/features/recurring/domain/repositories/recurring_repository.dart';

class MaterializeRecurringInstanceUseCase {
  final RecurringRepository _repository;

  MaterializeRecurringInstanceUseCase(this._repository);

  Future<void> call(String ruleId, DateTime date) {
    return _repository.materialize(ruleId, date);
  }
}

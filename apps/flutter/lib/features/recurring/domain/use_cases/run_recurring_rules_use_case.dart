import 'package:ownfinances/features/recurring/domain/repositories/recurring_repository.dart';

class RunRecurringRulesUseCase {
  final RecurringRepository _repository;

  RunRecurringRulesUseCase(this._repository);

  Future<Map<String, dynamic>> call(String period, DateTime date) {
    return _repository.run(period, date);
  }
}

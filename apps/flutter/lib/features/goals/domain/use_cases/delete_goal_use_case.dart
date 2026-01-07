import "package:ownfinances/features/goals/domain/repositories/goal_repository.dart";

class DeleteGoalUseCase {
  final GoalRepository repository;

  DeleteGoalUseCase(this.repository);

  Future<void> execute(String id) {
    return repository.delete(id);
  }
}

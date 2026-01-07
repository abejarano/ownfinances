import "package:ownfinances/features/goals/domain/entities/goal.dart";
import "package:ownfinances/features/goals/domain/repositories/goal_repository.dart";

class ListGoalsUseCase {
  final GoalRepository repository;

  ListGoalsUseCase(this.repository);

  Future<List<Goal>> execute() {
    return repository.list();
  }
}

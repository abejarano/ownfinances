import "package:ownfinances/features/goals/domain/entities/goal_projection.dart";
import "package:ownfinances/features/goals/domain/repositories/goal_repository.dart";

class GetGoalProjectionUseCase {
  final GoalRepository repository;

  GetGoalProjectionUseCase(this.repository);

  Future<GoalProjection> execute(String id) {
    return repository.projection(id);
  }
}

import "package:ownfinances/features/goals/domain/entities/goal.dart";
import "package:ownfinances/features/goals/domain/repositories/goal_repository.dart";

class UpdateGoalUseCase {
  final GoalRepository repository;

  UpdateGoalUseCase(this.repository);

  Future<Goal> execute({
    required String id,
    String? name,
    double? targetAmount,
    String? currency,
    DateTime? startDate,
    DateTime? targetDate,
    double? monthlyContribution,
    String? linkedAccountId,
    bool? isActive,
  }) {
    return repository.update(
      id,
      name: name,
      targetAmount: targetAmount,
      currency: currency,
      startDate: startDate,
      targetDate: targetDate,
      monthlyContribution: monthlyContribution,
      linkedAccountId: linkedAccountId,
      isActive: isActive,
    );
  }
}

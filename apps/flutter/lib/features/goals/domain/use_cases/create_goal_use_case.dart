import "package:ownfinances/features/goals/domain/entities/goal.dart";
import "package:ownfinances/features/goals/domain/repositories/goal_repository.dart";

class CreateGoalUseCase {
  final GoalRepository repository;

  CreateGoalUseCase(this.repository);

  Future<Goal> execute({
    required String name,
    required double targetAmount,
    String? currency,
    required DateTime startDate,
    DateTime? targetDate,
    double? monthlyContribution,
    String? linkedAccountId,
    bool? isActive,
  }) {
    return repository.create(
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

import "package:ownfinances/features/goals/domain/repositories/goal_repository.dart";

class CreateGoalContributionUseCase {
  final GoalRepository repository;

  CreateGoalContributionUseCase(this.repository);

  Future<void> execute({
    required String goalId,
    required DateTime date,
    required double amount,
    String? accountId,
    String? note,
  }) {
    return repository.createContribution(
      goalId: goalId,
      date: date,
      amount: amount,
      accountId: accountId,
      note: note,
    );
  }
}

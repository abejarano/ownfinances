import "package:ownfinances/features/goals/domain/entities/goal.dart";
import "package:ownfinances/features/goals/domain/entities/goal_projection.dart";

abstract class GoalRepository {
  Future<List<Goal>> list();
  Future<Goal> create({
    required String name,
    required double targetAmount,
    String? currency,
    required DateTime startDate,
    DateTime? targetDate,
    double? monthlyContribution,
    String? linkedAccountId,
    bool? isActive,
  });
  Future<Goal> update(
    String id, {
    String? name,
    double? targetAmount,
    String? currency,
    DateTime? startDate,
    DateTime? targetDate,
    double? monthlyContribution,
    String? linkedAccountId,
    bool? isActive,
  });
  Future<void> delete(String id);
  Future<GoalProjection> projection(String id);
  Future<void> createContribution({
    required String goalId,
    required DateTime date,
    required double amount,
    String? accountId,
    String? note,
  });
}

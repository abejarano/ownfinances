import "package:ownfinances/features/goals/data/datasources/goal_remote_data_source.dart";
import "package:ownfinances/features/goals/domain/entities/goal.dart";
import "package:ownfinances/features/goals/domain/entities/goal_projection.dart";
import "package:ownfinances/features/goals/domain/repositories/goal_repository.dart";

class GoalRepositoryImpl implements GoalRepository {
  final GoalRemoteDataSource remote;

  GoalRepositoryImpl(this.remote);

  @override
  Future<List<Goal>> list() async {
    final payload = await remote.list();
    final results = payload["results"] as List<dynamic>? ?? [];
    return results
        .map((item) => Goal.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Goal> create({
    required String name,
    required double targetAmount,
    String? currency,
    required DateTime startDate,
    DateTime? targetDate,
    double? monthlyContribution,
    String? linkedAccountId,
    bool? isActive,
  }) async {
    final payload = await remote.create({
      "name": name,
      "targetAmount": targetAmount,
      "currency": currency,
      "startDate": startDate.toIso8601String(),
      "targetDate": targetDate?.toIso8601String(),
      "monthlyContribution": monthlyContribution,
      "linkedAccountId": linkedAccountId,
      "isActive": isActive,
    });
    return Goal.fromJson(payload);
  }

  @override
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
  }) async {
    final payload = await remote.update(id, {
      "name": name,
      "targetAmount": targetAmount,
      "currency": currency,
      "startDate": startDate?.toIso8601String(),
      "targetDate": targetDate?.toIso8601String(),
      "monthlyContribution": monthlyContribution,
      "linkedAccountId": linkedAccountId,
      "isActive": isActive,
    });
    return Goal.fromJson(payload);
  }

  @override
  Future<void> delete(String id) {
    return remote.delete(id);
  }

  @override
  Future<GoalProjection> projection(String id) async {
    final payload = await remote.projection(id);
    return GoalProjection.fromJson(payload);
  }

  @override
  Future<void> createContribution({
    required String goalId,
    required DateTime date,
    required double amount,
    String? accountId,
    String? note,
  }) {
    return remote.createContribution(goalId, {
      "date": date.toIso8601String(),
      "amount": amount,
      "accountId": accountId,
      "note": note,
    });
  }
}

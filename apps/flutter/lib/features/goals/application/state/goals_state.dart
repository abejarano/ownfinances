import "package:ownfinances/features/goals/domain/entities/goal.dart";
import "package:ownfinances/features/goals/domain/entities/goal_projection.dart";

class GoalsState {
  final List<Goal> items;
  final Map<String, GoalProjection> projections;
  final bool isLoading;
  final String? error;
  final String? lastAccountId;

  const GoalsState({
    required this.items,
    required this.projections,
    required this.isLoading,
    required this.error,
    required this.lastAccountId,
  });

  GoalsState copyWith({
    List<Goal>? items,
    Map<String, GoalProjection>? projections,
    bool? isLoading,
    String? error,
    String? lastAccountId,
  }) {
    return GoalsState(
      items: items ?? this.items,
      projections: projections ?? this.projections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastAccountId: lastAccountId ?? this.lastAccountId,
    );
  }

  static GoalsState initial() {
    return const GoalsState(
      items: [],
      projections: {},
      isLoading: false,
      error: null,
      lastAccountId: null,
    );
  }
}

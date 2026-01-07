import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/goals/application/state/goals_state.dart";
import "package:ownfinances/features/goals/domain/entities/goal_projection.dart";
import "package:ownfinances/features/goals/domain/repositories/goal_repository.dart";

class GoalsController extends ChangeNotifier {
  final GoalRepository repository;

  GoalsState _state = GoalsState.initial();

  GoalsController(this.repository);

  GoalsState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final items = await repository.list();
      final projections = <String, GoalProjection>{};
      for (final goal in items) {
        try {
          projections[goal.id] = await repository.projection(goal.id);
        } catch (_) {
          // Keep screen usable if projection fails for one goal.
        }
      }
      _state = _state.copyWith(
        isLoading: false,
        items: items,
        projections: projections,
      );
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  Future<String?> create({
    required String name,
    required double targetAmount,
    String? currency,
    required DateTime startDate,
    DateTime? targetDate,
    double? monthlyContribution,
    String? linkedAccountId,
    bool? isActive,
  }) async {
    try {
      final created = await repository.create(
        name: name,
        targetAmount: targetAmount,
        currency: currency,
        startDate: startDate,
        targetDate: targetDate,
        monthlyContribution: monthlyContribution,
        linkedAccountId: linkedAccountId,
        isActive: isActive,
      );
      _state = _state.copyWith(items: [created, ..._state.items]);
      notifyListeners();
      await _refreshProjection(created.id);
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<String?> update({
    required String id,
    String? name,
    double? targetAmount,
    String? currency,
    DateTime? startDate,
    DateTime? targetDate,
    double? monthlyContribution,
    String? linkedAccountId,
    bool? isActive,
  }) async {
    try {
      final updated = await repository.update(
        id: id,
        name: name,
        targetAmount: targetAmount,
        currency: currency,
        startDate: startDate,
        targetDate: targetDate,
        monthlyContribution: monthlyContribution,
        linkedAccountId: linkedAccountId,
        isActive: isActive,
      );
      _state = _state.copyWith(
        items: _state.items
            .map((item) => item.id == id ? updated : item)
            .toList(),
      );
      notifyListeners();
      await _refreshProjection(id);
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<String?> remove(String id) async {
    try {
      await repository.delete(id);
      final next = Map<String, GoalProjection>.from(_state.projections);
      next.remove(id);
      _state = _state.copyWith(
        items: _state.items.where((item) => item.id != id).toList(),
        projections: next,
      );
      notifyListeners();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<String?> createContribution({
    required String goalId,
    required DateTime date,
    required double amount,
    String? accountId,
    String? note,
  }) async {
    try {
      await repository.createContribution(
        goalId: goalId,
        date: date,
        amount: amount,
        accountId: accountId,
        note: note,
      );
      _state = _state.copyWith(lastAccountId: accountId ?? _state.lastAccountId);
      notifyListeners();
      await _refreshProjection(goalId);
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<void> _refreshProjection(String goalId) async {
    try {
      final projection = await repository.projection(goalId);
      final next = Map<String, GoalProjection>.from(_state.projections);
      next[goalId] = projection;
      _state = _state.copyWith(projections: next);
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado";
  }
}

import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/budgets/application/state/budget_state.dart";
import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/budgets/domain/use_cases/get_current_budget_use_case.dart";
import "package:ownfinances/features/budgets/domain/use_cases/save_budget_use_case.dart";

class BudgetController extends ChangeNotifier {
  final GetCurrentBudgetUseCase currentUseCase;
  final SaveBudgetUseCase saveUseCase;
  BudgetState _state = BudgetState.initial;

  BudgetController(this.currentUseCase, this.saveUseCase);

  BudgetState get state => _state;

  Future<void> load({required String period, required DateTime date}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final current = await currentUseCase.execute(period: period, date: date);
      final planned = <String, double>{};
      if (current.budget != null) {
        for (final line in current.budget!.lines) {
          planned[line.categoryId] = line.plannedAmount;
        }
      }
      _state = _state.copyWith(
        isLoading: false,
        budget: current.budget,
        range: current.range,
        plannedByCategory: planned,
      );
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  void updatePlanned(String categoryId, double amount) {
    final next = Map<String, double>.from(_state.plannedByCategory);
    next[categoryId] = amount;
    _state = _state.copyWith(plannedByCategory: next);
    notifyListeners();
  }

  Future<String?> save(String period) async {
    if (_state.range == null) return "Periodo inválido";
    try {
      final lines = _state.plannedByCategory.entries
          .map(
            (entry) =>
                BudgetLine(categoryId: entry.key, plannedAmount: entry.value),
          )
          .toList();
      final saved = await saveUseCase.execute(
        id: _state.budget?.id,
        period: period,
        startDate: _state.range!.start,
        endDate: _state.range!.end,
        lines: lines,
      );
      _state = _state.copyWith(budget: saved);
      notifyListeners();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado";
  }
}

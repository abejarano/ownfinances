import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/budgets/application/state/budget_state.dart";
import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/budgets/data/repositories/budget_repository.dart";

class BudgetController extends ChangeNotifier {
  final BudgetRepository repository;
  BudgetState _state = BudgetState.initial;

  BudgetController(this.repository);

  BudgetState get state => _state;

  DateTime? _loadingDate; // Guard for race conditions

  Future<void> load({required String period, required DateTime date}) async {
    _loadingDate = date;

    // Clear state completely before loading to prevent stale data
    _state = BudgetState.initial.copyWith(isLoading: true);
    notifyListeners();
    try {
      final current = await repository.current(period: period, date: date);

      // If another load started for a different date, ignore this result
      if (_loadingDate != date) return;

      final planned = <String, double>{};
      final plannedDebts = <String, double>{};
      if (current.budget != null) {
        for (final line in current.budget!.lines) {
          planned[line.categoryId] = line.plannedAmount;
        }
        for (final payment in current.budget!.debtPayments) {
          plannedDebts[payment.debtId] = payment.plannedAmount;
        }
      }
      _state = _state.copyWith(
        isLoading: false,
        budget: current.budget,
        range: current.range,
        plannedByCategory: planned,
        plannedByDebt: plannedDebts,
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

  void updatePlannedDebt(String debtId, double amount) {
    final next = Map<String, double>.from(_state.plannedByDebt);
    next[debtId] = amount;
    _state = _state.copyWith(plannedByDebt: next);
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
      final debtPayments = _state.plannedByDebt.entries
          .map(
            (entry) => BudgetDebtPayment(
              debtId: entry.key,
              plannedAmount: entry.value,
            ),
          )
          .toList();
      final saved = await repository.save(
        id: _state.budget?.id,
        period: period,
        startDate: _state.range!.start,
        endDate: _state.range!.end,
        lines: lines,
        debtPayments: debtPayments,
      );
      _state = _state.copyWith(budget: saved);
      notifyListeners();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<String?> removeCategory(
    String period,
    DateTime date,
    String categoryId,
  ) async {
    try {
      final updatedBudget = await repository.removeLine(
        period: period,
        date: date,
        categoryId: categoryId,
      );

      final nextPlanned = Map<String, double>.from(_state.plannedByCategory);
      nextPlanned.remove(categoryId);

      _state = _state.copyWith(
        budget: updatedBudget,
        plannedByCategory: nextPlanned,
      );
      notifyListeners();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<String?> createFromPrevious(String period, DateTime date) async {
    try {
      Map<String, double> planned = {};
      Map<String, double> plannedDebts = {};

      // Search backwards up to 12 months for a budget to copy
      for (int i = 1; i <= 12; i++) {
        final previousDate = DateTime(date.year, date.month - i, 1);
        final result = await repository.current(
          period: period,
          date: previousDate,
        );

        if (result.budget != null && result.budget!.lines.isNotEmpty) {
          // Found a budget! Copy and break.
          for (final line in result.budget!.lines) {
            if (line.plannedAmount > 0) {
              planned[line.categoryId] = line.plannedAmount;
            }
          }
          for (final payment in result.budget!.debtPayments) {
            if (payment.plannedAmount > 0) {
              plannedDebts[payment.debtId] = payment.plannedAmount;
            }
          }
          break;
        }
      }

      // 4. Update state with the copied values (or empty if none found)
      _state = _state.copyWith(
        plannedByCategory: planned,
        plannedByDebt: plannedDebts,
      );

      // 5. Save purely to persist this new 'copy' as the current month's budget
      return await save(period);
    } catch (error) {
      return _message(error);
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado";
  }
}

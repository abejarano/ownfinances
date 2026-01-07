import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/debts/application/state/debts_state.dart";
import "package:ownfinances/features/debts/domain/entities/debt_summary.dart";
import "package:ownfinances/features/debts/domain/use_cases/list_debts_use_case.dart";
import "package:ownfinances/features/debts/domain/use_cases/create_debt_use_case.dart";
import "package:ownfinances/features/debts/domain/use_cases/update_debt_use_case.dart";
import "package:ownfinances/features/debts/domain/use_cases/delete_debt_use_case.dart";
import "package:ownfinances/features/debts/domain/use_cases/get_debt_summary_use_case.dart";
import "package:ownfinances/features/debts/domain/use_cases/create_debt_transaction_use_case.dart";

class DebtsController extends ChangeNotifier {
  final ListDebtsUseCase listUseCase;
  final CreateDebtUseCase createUseCase;
  final UpdateDebtUseCase updateUseCase;
  final DeleteDebtUseCase deleteUseCase;
  final GetDebtSummaryUseCase getSummaryUseCase;
  final CreateDebtTransactionUseCase createDebtTransactionUseCase;

  DebtsState _state = DebtsState.initial();

  DebtsController(
    this.listUseCase,
    this.createUseCase,
    this.updateUseCase,
    this.deleteUseCase,
    this.getSummaryUseCase,
    this.createDebtTransactionUseCase,
  );

  DebtsState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final items = await listUseCase.execute();
      final summaries = <String, DebtSummary>{};
      for (final debt in items) {
        try {
          summaries[debt.id] = await getSummaryUseCase.execute(debt.id);
        } catch (_) {
          // Ignore summary errors per debt to keep list usable.
        }
      }
      _state = _state.copyWith(
        isLoading: false,
        items: items,
        summaries: summaries,
      );
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  Future<String?> create({
    required String name,
    required String type,
    String? currency,
    int? dueDay,
    double? minimumPayment,
    double? interestRateAnnual,
    bool? isActive,
  }) async {
    try {
      final created = await createUseCase.execute(
        name: name,
        type: type,
        currency: currency,
        dueDay: dueDay,
        minimumPayment: minimumPayment,
        interestRateAnnual: interestRateAnnual,
        isActive: isActive,
      );
      _state = _state.copyWith(items: [created, ..._state.items]);
      notifyListeners();
      await _refreshSummary(created.id);
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<String?> update({
    required String id,
    String? name,
    String? type,
    String? currency,
    int? dueDay,
    double? minimumPayment,
    double? interestRateAnnual,
    bool? isActive,
  }) async {
    try {
      final updated = await updateUseCase.execute(
        id: id,
        name: name,
        type: type,
        currency: currency,
        dueDay: dueDay,
        minimumPayment: minimumPayment,
        interestRateAnnual: interestRateAnnual,
        isActive: isActive,
      );
      _state = _state.copyWith(
        items: _state.items
            .map((item) => item.id == id ? updated : item)
            .toList(),
      );
      notifyListeners();
      await _refreshSummary(id);
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<String?> remove(String id) async {
    try {
      await deleteUseCase.execute(id);
      final nextSummaries = Map<String, DebtSummary>.from(_state.summaries);
      nextSummaries.remove(id);
      _state = _state.copyWith(
        items: _state.items.where((item) => item.id != id).toList(),
        summaries: nextSummaries,
      );
      notifyListeners();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<String?> createDebtTransaction({
    required String debtId,
    required DateTime date,
    required String type,
    required double amount,
    String? accountId,
    String? note,
  }) async {
    try {
      await createDebtTransactionUseCase.execute(
        debtId: debtId,
        date: date,
        type: type,
        amount: amount,
        accountId: accountId,
        note: note,
      );
      _state = _state.copyWith(lastAccountId: accountId ?? _state.lastAccountId);
      notifyListeners();
      await _refreshSummary(debtId);
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<void> _refreshSummary(String debtId) async {
    try {
      final summary = await getSummaryUseCase.execute(debtId);
      final next = Map<String, DebtSummary>.from(_state.summaries);
      next[debtId] = summary;
      _state = _state.copyWith(summaries: next);
      notifyListeners();
    } catch (_) {
      // Ignore summary refresh errors.
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado";
  }
}

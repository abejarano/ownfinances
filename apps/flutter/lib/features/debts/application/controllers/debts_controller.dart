import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/debts/application/state/debts_state.dart";
import "package:ownfinances/features/debts/domain/entities/debt_summary.dart";
import "package:ownfinances/features/debts/domain/entities/debt_transaction.dart";
import "package:ownfinances/features/debts/domain/repositories/debt_repository.dart";
import "package:ownfinances/features/debts/domain/repositories/debt_transaction_repository.dart";

class DebtsController extends ChangeNotifier {
  final DebtRepository debtRepository;
  final DebtTransactionRepository transactionRepository;

  DebtsState _state = DebtsState.initial();

  DebtsController(this.debtRepository, this.transactionRepository);

  DebtsState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final items = await debtRepository.list();
      final summaries = <String, DebtSummary>{};
      for (final debt in items) {
        try {
          summaries[debt.id] = await debtRepository.summary(debt.id);
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
    String? linkedAccountId,
    String? currency,
    int? dueDay,
    double? minimumPayment,
    double? interestRateAnnual,
    bool? isActive,
  }) async {
    try {
      final created = await debtRepository.create(
        name: name,
        type: type,
        linkedAccountId: linkedAccountId,
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
    String? linkedAccountId,
    String? currency,
    int? dueDay,
    double? minimumPayment,
    double? interestRateAnnual,
    bool? isActive,
  }) async {
    try {
      final updated = await debtRepository.update(
        id,
        name: name,
        type: type,
        linkedAccountId: linkedAccountId,
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
      await debtRepository.delete(id);
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
    String? categoryId,
    String? note,
  }) async {
    try {
      await transactionRepository.create(
        debtId: debtId,
        date: date,
        type: type,
        amount: amount,
        accountId: accountId,
        categoryId: categoryId,
        note: note,
      );
      _state = _state.copyWith(
        lastAccountId: accountId ?? _state.lastAccountId,
      );
      notifyListeners();
      await _refreshSummary(debtId);
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<void> _refreshSummary(String debtId) async {
    try {
      final summary = await debtRepository.summary(debtId);
      final next = Map<String, DebtSummary>.from(_state.summaries);
      next[debtId] = summary;
      _state = _state.copyWith(summaries: next);
      notifyListeners();
    } catch (_) {
      // Ignore summary refresh errors.
    }
  }

  Future<List<DebtTransaction>> loadHistory(
    String debtId, {
    String? month,
  }) async {
    try {
      return await debtRepository.history(debtId, month: month);
    } catch (error) {
      return [];
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado";
  }
}

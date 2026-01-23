import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/debts/application/state/debts_state.dart";
import "package:ownfinances/features/debts/domain/entities/debt_summary.dart";
import "package:ownfinances/features/debts/domain/entities/debt_transaction.dart";
import "package:ownfinances/features/debts/data/repositories/debt_repository.dart";
import "package:ownfinances/features/debts/data/repositories/debt_transaction_repository.dart";

class DebtsController extends ChangeNotifier {
  final DebtRepository debtRepository;
  final DebtTransactionRepository transactionRepository;

  DebtsState _state = DebtsState.initial();
  bool _isDisposed = false;

  DebtsController(this.debtRepository, this.transactionRepository);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  DebtsState get state => _state;

  Future<void> loadOverview() async {
    if (_isDisposed) return;
    _state = _state.copyWith(isLoadingOverview: true);
    notifyListeners();
    try {
      final overview = await debtRepository.getOverview();
      _state = _state.copyWith(overview: overview, isLoadingOverview: false);
    } catch (_) {
      // Allow silent failure or handle error specific to overview?
      if (!_isDisposed) {
        _state = _state.copyWith(isLoadingOverview: false);
      }
    }
    if (!_isDisposed) notifyListeners();
  }

  Future<void> load() async {
    loadOverview(); // Fire and forget or await? Let's fire and allow parallel loading.
    if (_isDisposed) return;
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final items = await debtRepository.list();
      _state = _state.copyWith(
        isLoading: false,
        items: items,
        // summaries: summaries, // No longer needed
      );
    } catch (error) {
      if (!_isDisposed) {
        _state = _state.copyWith(isLoading: false, error: _message(error));
      }
    }
    if (!_isDisposed) notifyListeners();
  }

  Future<String?> create({
    required String name,
    required String type,
    String? linkedAccountId,
    String? paymentAccountId,
    String? currency,
    int? dueDay,
    double? minimumPayment,
    double? interestRateAnnual,
    double? initialBalance,
    bool? isActive,
  }) async {
    try {
      final created = await debtRepository.create(
        name: name,
        type: type,
        linkedAccountId: linkedAccountId,
        paymentAccountId: paymentAccountId,
        currency: currency,
        dueDay: dueDay,
        minimumPayment: minimumPayment,
        interestRateAnnual: interestRateAnnual,
        initialBalance: initialBalance,
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
    String? paymentAccountId,
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
        paymentAccountId: paymentAccountId,
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
      if (!_isDisposed) notifyListeners();
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
      if (!_isDisposed) notifyListeners();
      await _refreshSummary(debtId);
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<void> _refreshSummary(String debtId) async {
    try {
      final summary = await debtRepository.summary(debtId);
      if (_isDisposed) return;
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

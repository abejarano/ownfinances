import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/budgets/application/state/budget_state.dart";
import "package:ownfinances/features/budgets/data/repositories/budget_repository.dart";
import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";

class BudgetController extends ChangeNotifier {
  final BudgetRepository repository;
  BudgetState _state = BudgetState.initial;

  BudgetController(this.repository);

  BudgetState get state => _state;

  DateTime? _loadingDate; // Guard for race conditions

  void reset() {
    _loadingDate = null;
    _state = BudgetState.initial;
    notifyListeners();
  }

  Future<void> load({required String period, required DateTime date}) async {
    _loadingDate = date;

    _state = BudgetState.initial.copyWith(isLoading: true);
    notifyListeners();
    try {
      final current = await repository.current(period: period, date: date);

      if (_loadingDate != date) return;

      final plannedDebts = <String, double>{};
      final budget = current.budget;
      if (budget != null) {
        for (final payment in budget.debtPayments) {
          plannedDebts[payment.debtId] = payment.plannedAmount;
        }
      }

      _state = _state.copyWith(
        isLoading: false,
        budget: budget,
        range: current.range,
        planCategories: budget?.categories ?? const [],
        plannedByDebt: plannedDebts,
        hasChanges: false,
        snapshotDismissed: false,
        overwriteSnapshot: true,
        snapshot: null,
      );
      notifyListeners();
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
      notifyListeners();
    }
  }

  Future<String?> addEntry({
    required String period,
    required DateTime date,
    required String categoryId,
    required double amount,
    required String currency,
    String? description,
  }) async {
    if (amount <= 0) return null;

    final entry = BudgetPlanEntry(
      id: _newEntryId(),
      amount: amount,
      currency: currency,
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      createdAt: DateTime.now(),
    );

    final nextCategories = <BudgetCategoryPlan>[];
    var found = false;
    for (final category in _state.planCategories) {
      if (category.categoryId == categoryId) {
        final updatedEntries = [...category.entries, entry];
        nextCategories.add(_withEntries(category, updatedEntries));
        found = true;
      } else {
        nextCategories.add(category);
      }
    }

    if (!found) {
      nextCategories.add(
        BudgetCategoryPlan(
          categoryId: categoryId,
          plannedTotal: {currency: amount},
          entries: [entry],
        ),
      );
    }

    // Try to save to API
    final range = _state.range ?? _fallbackRange(period, date);
    if (range == null) return "Periodo inválido";

    try {
      final debtPayments = _state.plannedByDebt.entries
          .where((entry) => entry.value > 0)
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
        startDate: range.start,
        endDate: range.end,
        categories: nextCategories,
        debtPayments: debtPayments,
      );

      _state = _state.copyWith(
        budget: saved,
        range: range,
        planCategories: nextCategories,
        hasChanges: false, // Saved!
        snapshotDismissed: true,
      );
      notifyListeners();
      return null;
    } catch (error) {
      // Do not update state if failed
      return _message(error);
    }
  }

  void removeEntry(String entryId) {
    final nextCategories = <BudgetCategoryPlan>[];
    for (final category in _state.planCategories) {
      final updatedEntries = category.entries
          .where((entry) => entry.id != entryId)
          .toList();
      if (updatedEntries.isEmpty) continue;
      nextCategories.add(_withEntries(category, updatedEntries));
    }

    _state = _state.copyWith(
      planCategories: nextCategories,
      hasChanges: true,
      snapshotDismissed: true,
    );
    notifyListeners();
  }

  void removeCategoryEntries(String categoryId) {
    final nextCategories = _state.planCategories
        .where((category) => category.categoryId != categoryId)
        .toList();

    _state = _state.copyWith(
      planCategories: nextCategories,
      hasChanges: true,
      snapshotDismissed: true,
    );
    notifyListeners();
  }

  void clearPlan() {
    final hadData =
        _state.planCategories.isNotEmpty ||
        _state.plannedByDebt.values.any((value) => value > 0) ||
        _state.budget != null;
    _state = _state.copyWith(
      planCategories: const [],
      plannedByDebt: const {},
      snapshotDismissed: true,
      hasChanges: hadData,
    );
    notifyListeners();
  }

  Future<bool> applySnapshot({
    required String period,
    required DateTime date,
  }) async {
    final snapshot = await _findSnapshot(period, date);
    if (snapshot == null) {
      _state = _state.copyWith(
        snapshot: null,
        overwriteSnapshot: true,
        snapshotDismissed: true,
      );
      notifyListeners();
      return false;
    }
    _state = _state.copyWith(
      planCategories: snapshot.categories,
      plannedByDebt: snapshot.plannedByDebt,
      hasChanges: true,
      snapshotDismissed: true,
      snapshot: snapshot,
      overwriteSnapshot: true,
    );
    notifyListeners();
    return true;
  }

  void dismissSnapshot() {
    _state = _state.copyWith(snapshotDismissed: true);
    notifyListeners();
  }

  void updatePlannedDebt(String debtId, double amount) {
    final next = Map<String, double>.from(_state.plannedByDebt);
    next[debtId] = amount;
    _state = _state.copyWith(
      plannedByDebt: next,
      hasChanges: true,
      snapshotDismissed: true,
    );
    notifyListeners();
  }

  Future<String?> save(String period, {required DateTime date}) async {
    final range = _state.range ?? _fallbackRange(period, date);
    if (range == null) return "Periodo inválido";
    try {
      final debtPayments = _state.plannedByDebt.entries
          .where((entry) => entry.value > 0)
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
        startDate: range.start,
        endDate: range.end,
        categories: _state.planCategories,
        debtPayments: debtPayments,
      );
      _state = _state.copyWith(budget: saved, range: range, hasChanges: false);
      notifyListeners();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  ReportRange? _fallbackRange(String period, DateTime date) {
    if (period != "monthly") return null;
    final start = DateTime.utc(date.year, date.month, 1);
    final end = DateTime.utc(date.year, date.month + 1, 0, 23, 59, 59, 999);
    return ReportRange(start: start, end: end);
  }

  Future<BudgetSnapshot?> _findSnapshot(String period, DateTime date) async {
    final previousDate = DateTime(date.year, date.month - 1, 1);
    final result = await repository.current(period: period, date: previousDate);

    if (result.budget == null) return null;

    final categories = result.budget!.categories;
    final plannedDebts = <String, double>{};
    for (final payment in result.budget!.debtPayments) {
      if (payment.plannedAmount > 0) {
        plannedDebts[payment.debtId] = payment.plannedAmount;
      }
    }

    if (categories.isEmpty && plannedDebts.isEmpty) {
      return null;
    }

    return BudgetSnapshot(categories: categories, plannedByDebt: plannedDebts);
  }

  BudgetCategoryPlan _withEntries(
    BudgetCategoryPlan category,
    List<BudgetPlanEntry> entries,
  ) {
    final plannedTotal = <String, double>{};
    for (final entry in entries) {
      plannedTotal[entry.currency] =
          (plannedTotal[entry.currency] ?? 0.0) + entry.amount;
    }
    return BudgetCategoryPlan(
      categoryId: category.categoryId,
      plannedTotal: plannedTotal,
      entries: entries,
    );
  }

  String _newEntryId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado";
  }
}

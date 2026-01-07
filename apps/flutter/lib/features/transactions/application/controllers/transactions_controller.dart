import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/transactions/application/state/transactions_state.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";
import "package:ownfinances/features/transactions/domain/use_cases/clear_transaction_use_case.dart";
import "package:ownfinances/features/transactions/domain/use_cases/create_transaction_use_case.dart";
import "package:ownfinances/features/transactions/domain/use_cases/delete_transaction_use_case.dart";
import "package:ownfinances/features/transactions/domain/use_cases/list_transactions_use_case.dart";
import "package:ownfinances/features/transactions/domain/use_cases/update_transaction_use_case.dart";
import "package:ownfinances/features/transactions/domain/use_cases/restore_transaction_use_case.dart";

class TransactionsController extends ChangeNotifier {
  final ListTransactionsUseCase listUseCase;
  final CreateTransactionUseCase createUseCase;
  final UpdateTransactionUseCase updateUseCase;
  final DeleteTransactionUseCase deleteUseCase;
  final ClearTransactionUseCase clearUseCase;
  final RestoreTransactionUseCase restoreUseCase;
  TransactionsState _state = TransactionsState.initial();

  TransactionsController(
    this.listUseCase,
    this.createUseCase,
    this.updateUseCase,
    this.deleteUseCase,
    this.clearUseCase,
    this.restoreUseCase,
  );

  TransactionsState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final result = await listUseCase.execute(filters: _state.filters);
      _state = _state.copyWith(isLoading: false, items: result.results);
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  Future<void> setFilters(TransactionFilters filters) async {
    _state = _state.copyWith(filters: filters);
    notifyListeners();
    await load();
  }

  Future<Transaction?> create(Map<String, dynamic> payload) async {
    try {
      final created = await createUseCase.execute(payload);
      _state = _state.copyWith(items: [created, ..._state.items]);
      notifyListeners();
      return created;
    } catch (error) {
      _state = _state.copyWith(error: _message(error));
      notifyListeners();
      return null;
    }
  }

  Future<Transaction?> update(String id, Map<String, dynamic> payload) async {
    try {
      final updated = await updateUseCase.execute(id, payload);
      final next = _state.items
          .map((item) => item.id == id ? updated : item)
          .toList();
      _state = _state.copyWith(items: next);
      notifyListeners();
      return updated;
    } catch (error) {
      _state = _state.copyWith(error: _message(error));
      notifyListeners();
      return null;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await deleteUseCase.execute(id);
      _state = _state.copyWith(
        items: _state.items.where((item) => item.id != id).toList(),
      );
      notifyListeners();
      return true;
    } catch (error) {
      _state = _state.copyWith(error: _message(error));
      notifyListeners();
      return false;
    }
  }

  Future<Transaction?> clear(String id) async {
    try {
      final cleared = await clearUseCase.execute(id);
      final next = _state.items
          .map((item) => item.id == id ? cleared : item)
          .toList();
      _state = _state.copyWith(items: next);
      notifyListeners();
      return cleared;
    } catch (error) {
      _state = _state.copyWith(error: _message(error));
      notifyListeners();
      return null;
    }
  }

  Future<Transaction?> restore(String id) async {
    try {
      final restored = await restoreUseCase.execute(id);
      _state = _state.copyWith(items: [restored, ..._state.items]);
      notifyListeners();
      return restored;
    } catch (error) {
      _state = _state.copyWith(error: _message(error));
      notifyListeners();
      return null;
    }
  }

  void rememberDefaults(Transaction transaction) {
    _state = _state.copyWith(
      lastCategoryId: transaction.categoryId ?? _state.lastCategoryId,
      lastFromAccountId: transaction.fromAccountId ?? _state.lastFromAccountId,
      lastToAccountId: transaction.toAccountId ?? _state.lastToAccountId,
    );
    notifyListeners();
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado";
  }
}

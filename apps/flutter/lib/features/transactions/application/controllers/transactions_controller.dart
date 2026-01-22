import "package:ownfinances/features/transactions/domain/entities/transaction_filters.dart";
import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/transactions/application/state/transactions_state.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_delete_response.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_write_response.dart";
import "package:ownfinances/features/transactions/data/repositories/transaction_repository.dart";

class TransactionsController extends ChangeNotifier {
  final TransactionRepository repository;
  TransactionsState _state = TransactionsState.initial();

  TransactionsController(this.repository);

  TransactionsState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final result = await repository.list(filters: _state.filters);
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
      final created = await repository.create(payload);
      _state = _state.copyWith(items: [created, ..._state.items]);
      notifyListeners();
      return created;
    } catch (error) {
      _state = _state.copyWith(error: _message(error));
      notifyListeners();
      return null;
    }
  }

  Future<TransactionWriteResponse?> createWithImpact({
    required Map<String, dynamic> payload,
    required String period,
  }) async {
    try {
      final created = await repository.createWithImpact(
        payload: payload,
        period: period,
      );
      _state = _state.copyWith(items: [created.transaction, ..._state.items]);
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
      final updated = await repository.update(id, payload);
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

  Future<TransactionWriteResponse?> updateWithImpact({
    required String id,
    required Map<String, dynamic> payload,
    required String period,
  }) async {
    try {
      final updated = await repository.updateWithImpact(
        id: id,
        payload: payload,
        period: period,
      );
      final next = _state.items
          .map((item) => item.id == id ? updated.transaction : item)
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
      await repository.delete(id);
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

  Future<TransactionDeleteResponse?> removeWithImpact({
    required String id,
    required String period,
  }) async {
    try {
      final result = await repository.deleteWithImpact(id: id, period: period);
      if (result.ok) {
        _state = _state.copyWith(
          items: _state.items.where((item) => item.id != id).toList(),
        );
      }
      notifyListeners();
      return result;
    } catch (error) {
      _state = _state.copyWith(error: _message(error));
      notifyListeners();
      return null;
    }
  }

  Future<Transaction?> clear(String id) async {
    try {
      final cleared = await repository.clear(id);
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

  Future<TransactionWriteResponse?> clearWithImpact({
    required String id,
    required String period,
  }) async {
    try {
      final cleared = await repository.clearWithImpact(id: id, period: period);
      final next = _state.items
          .map((item) => item.id == id ? cleared.transaction : item)
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
      final restored = await repository.restore(id);
      _state = _state.copyWith(items: [restored, ..._state.items]);
      notifyListeners();
      return restored;
    } catch (error) {
      _state = _state.copyWith(error: _message(error));
      notifyListeners();
      return null;
    }
  }

  Future<TransactionWriteResponse?> restoreWithImpact({
    required String id,
    required String period,
  }) async {
    try {
      final restored = await repository.restoreWithImpact(id: id, period: period);
      _state = _state.copyWith(items: [restored.transaction, ..._state.items]);
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

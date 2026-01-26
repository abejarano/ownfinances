import 'package:flutter/material.dart';
import 'package:ownfinances/core/infrastructure/api/api_exception.dart';
import 'package:ownfinances/features/transactions/application/state/pending_transactions_state.dart';
import 'package:ownfinances/features/transactions/domain/entities/transaction.dart';
import 'package:ownfinances/features/transactions/data/repositories/transaction_repository.dart';

class PendingTransactionsController extends ChangeNotifier {
  final TransactionRepository repository;

  PendingTransactionsState _state = PendingTransactionsState.initial();

  PendingTransactionsController(this.repository);

  PendingTransactionsState get state => _state;

  void reset() {
    _state = PendingTransactionsState.initial();
    notifyListeners();
  }

  Future<void> loadPending({
    String? month,
    String? categoryId,
    String? recurringRuleId,
  }) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final results = await repository.listPending(
        month: month,
        categoryId: categoryId,
        recurringRuleId: recurringRuleId,
      );
      _state = _state.copyWith(isLoading: false, items: results);
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  Future<bool> confirmAll() async {
    if (_state.items.isEmpty) return false;
    
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    
    try {
      final ids = _state.items.map((t) => t.id).toList();
      final count = await repository.confirmBatch(ids);
      
      _state = _state.copyWith(
        isLoading: false,
        items: [],
      );
      notifyListeners();
      return count > 0;
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmSingle(String transactionId) async {
    try {
      final count = await repository.confirmBatch([transactionId]);
      if (count > 0) {
        _state = _state.copyWith(
          items: _state.items.where((t) => t.id != transactionId).toList(),
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (error) {
      _state = _state.copyWith(error: _message(error));
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSingle(String transactionId) async {
    try {
      await repository.delete(transactionId);
      _state = _state.copyWith(
        items: _state.items.where((t) => t.id != transactionId).toList(),
      );
      notifyListeners();
      return true;
    } catch (error) {
      _state = _state.copyWith(error: _message(error));
      notifyListeners();
      return false;
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado: $error";
  }
}

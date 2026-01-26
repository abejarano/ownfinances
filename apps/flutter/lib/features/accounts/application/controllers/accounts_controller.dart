import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/accounts/application/state/accounts_state.dart";
import "package:ownfinances/features/accounts/data/repositories/account_repository.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";

class AccountsController extends ChangeNotifier {
  final AccountRepository repository;
  AccountsState _state = AccountsState.initial;
  bool _isDisposed = false;

  AccountsController(this.repository);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  AccountsState get state => _state;

  void reset() {
    _state = AccountsState.initial;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> load() async {
    if (_isDisposed) return;
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final result = await repository.list(isActive: true);
      _state = _state.copyWith(isLoading: false, items: result.results);
    } catch (error) {
      if (!_isDisposed) {
        _state = _state.copyWith(isLoading: false, error: _message(error));
      }
    }
    if (!_isDisposed) notifyListeners();
  }

  Future<({Account? account, String? error})> create({
    required String name,
    required String type,
    String currency = "BRL",

    bool isActive = true,
    String? bankType,
  }) async {
    try {
      final created = await repository.create(
        name: name,
        type: type,
        currency: currency,
        isActive: isActive,
        bankType: bankType,
      );
      final next = [..._state.items, created]
        ..sort((a, b) => a.name.compareTo(b.name));
      _state = _state.copyWith(items: next);
      if (!_isDisposed) notifyListeners();
      return (account: created, error: null);
    } catch (error) {
      return (account: null, error: _message(error));
    }
  }

  Future<String?> update({
    required String id,
    required String name,
    required String type,
    required String currency,
    required bool isActive,
    String? bankType,
  }) async {
    try {
      final updated = await repository.update(
        id,
        name: name,
        type: type,
        currency: currency,
        isActive: isActive,
        bankType: bankType,
      );
      final next =
          _state.items.map((item) => item.id == id ? updated : item).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      _state = _state.copyWith(items: next);
      if (!_isDisposed) notifyListeners();
      return null;
    } catch (error) {
      return _message(error);
    }
  }

  Future<String?> remove(String id) async {
    try {
      await repository.delete(id);
      _state = _state.copyWith(
        items: _state.items.where((item) => item.id != id).toList(),
      );
      if (!_isDisposed) notifyListeners();
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

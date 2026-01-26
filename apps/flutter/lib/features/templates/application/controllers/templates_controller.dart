import 'package:flutter/material.dart';
import 'package:ownfinances/features/templates/domain/entities/transaction_template.dart';
import 'package:ownfinances/features/templates/data/repositories/template_repository.dart';

class TemplatesState {
  final bool isLoading;
  final String? error;
  final List<TransactionTemplate> items;

  TemplatesState({this.isLoading = false, this.error, this.items = const []});

  TemplatesState copyWith({
    bool? isLoading,
    String? error,
    List<TransactionTemplate>? items,
  }) {
    return TemplatesState(
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // Nullify error on new state unless explicitly passed? No, usually clear it on start
      items: items ?? this.items,
    );
  }
}

class TemplatesController extends ChangeNotifier {
  final TemplateRepository _repository;
  TemplatesState _state = TemplatesState();

  TemplatesController(this._repository);

  TemplatesState get state => _state;

  void reset() {
    _state = TemplatesState();
    notifyListeners();
  }

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final items = await _repository.list();
      _state = _state.copyWith(isLoading: false, items: items);
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
    }
    notifyListeners();
  }

  Future<TransactionTemplate?> create(Map<String, dynamic> payload) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final item = await _repository.create(payload);
      _state = _state.copyWith(
        isLoading: false,
        items: [item, ..._state.items],
      );
      notifyListeners();
      return item;
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
      return null;
    }
  }

  Future<void> delete(String id) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      await _repository.delete(id);
      _state = _state.copyWith(
        isLoading: false,
        items: _state.items.where((i) => i.id != id).toList(),
      );
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
    }
    notifyListeners();
  }
}

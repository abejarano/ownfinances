import 'package:flutter/material.dart';
import 'package:ownfinances/core/infrastructure/api/api_exception.dart';
import 'package:ownfinances/features/recurring/application/state/recurring_state.dart';
import 'package:ownfinances/features/recurring/domain/entities/recurring_rule.dart';
import 'package:ownfinances/features/recurring/domain/repositories/recurring_repository.dart';

class RecurringController extends ChangeNotifier {
  final RecurringRepository repository;

  RecurringState _state = RecurringState.initial();

  RecurringController(this.repository);

  RecurringState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final results = await repository.list();
      _state = _state.copyWith(isLoading: false, items: results);
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  Future<RecurringRule?> create(Map<String, dynamic> payload) async {
    _state = _state.copyWith(
      isLoading: true,
      error: null,
    ); // Optional loading for create
    notifyListeners();
    try {
      final created = await repository.create(payload);
      _state = _state.copyWith(
        isLoading: false,
        items: [created, ..._state.items],
      );
      notifyListeners();
      return created;
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(String id) async {
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

  Future<List<RecurringPreviewItem>?> preview(
    String period,
    DateTime date,
  ) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final result = await repository.preview(period, date);
      _state = _state.copyWith(isLoading: false, previewItems: result);
      notifyListeners();
      return result;
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> run(String period, DateTime date) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final result = await repository.run(period, date);
      _state = _state.copyWith(
        isLoading: false,
        previewItems: [],
      ); // Clear preview
      notifyListeners();
      return result;
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
      notifyListeners();
      return null;
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado: $error";
  }

  Future<void> materialize(String ruleId, DateTime date) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      await repository.materialize(ruleId, date);
      // We might want to refresh the list or transactions list, but usually this navigated to a form
      _state = _state.copyWith(isLoading: false);
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  Future<void> split(
    String ruleId,
    DateTime date,
    Map<String, dynamic> template,
  ) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      await repository.split(ruleId, date, template);
      // Refresh list to show new rule
      final results = await repository.list();
      _state = _state.copyWith(isLoading: false, items: results);
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }
}

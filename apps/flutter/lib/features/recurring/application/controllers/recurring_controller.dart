import 'package:flutter/material.dart';
import 'package:ownfinances/core/infrastructure/api/api_exception.dart';
import 'package:ownfinances/features/recurring/application/state/recurring_state.dart';
import 'package:ownfinances/features/recurring/domain/entities/recurring_rule.dart';
import 'package:ownfinances/features/recurring/domain/use_cases/create_recurring_rule_use_case.dart';
import 'package:ownfinances/features/recurring/domain/use_cases/delete_recurring_rule_use_case.dart';
import 'package:ownfinances/features/recurring/domain/use_cases/list_recurring_rules_use_case.dart';
import 'package:ownfinances/features/recurring/domain/use_cases/preview_recurring_rules_use_case.dart';
import 'package:ownfinances/features/recurring/domain/use_cases/run_recurring_rules_use_case.dart';
import 'package:ownfinances/features/recurring/domain/use_cases/split_recurring_rule_use_case.dart';
import 'package:ownfinances/features/recurring/domain/use_cases/materialize_recurring_instance_use_case.dart';

class RecurringController extends ChangeNotifier {
  final ListRecurringRulesUseCase listUseCase;
  final CreateRecurringRuleUseCase createUseCase;
  final DeleteRecurringRuleUseCase deleteUseCase;
  final PreviewRecurringRulesUseCase previewUseCase;
  final RunRecurringRulesUseCase runUseCase;
  final SplitRecurringRuleUseCase splitUseCase;
  final MaterializeRecurringInstanceUseCase materializeUseCase;

  RecurringState _state = RecurringState.initial();

  RecurringController(
    this.listUseCase,
    this.createUseCase,
    this.deleteUseCase,
    this.previewUseCase,
    this.runUseCase,
    this.splitUseCase,
    this.materializeUseCase,
  );

  RecurringState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final results = await listUseCase();
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
      final created = await createUseCase(payload);
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
      await deleteUseCase(id);
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
      final result = await previewUseCase(period, date);
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
      final result = await runUseCase(period, date);
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
      await materializeUseCase(ruleId, date);
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
      await splitUseCase(ruleId, date, template);
      // Refresh list to show new rule
      final results = await listUseCase();
      _state = _state.copyWith(isLoading: false, items: results);
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }
}

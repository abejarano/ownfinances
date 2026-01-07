import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/reports/application/state/reports_state.dart";
import "package:ownfinances/features/reports/domain/use_cases/get_summary_use_case.dart";
import "package:ownfinances/features/reports/domain/use_cases/get_balances_use_case.dart";

class ReportsController extends ChangeNotifier {
  final GetSummaryUseCase getSummaryUseCase;
  final GetBalancesUseCase getBalancesUseCase;
  ReportsState _state = ReportsState.initial();

  ReportsController(this.getSummaryUseCase, this.getBalancesUseCase);

  ReportsState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final summary = await getSummaryUseCase.execute(
        period: _state.period,
        date: _state.date,
      );
      final balances = await getBalancesUseCase.execute(
        period: _state.period,
        date: _state.date,
      );
      _state = _state.copyWith(
        isLoading: false,
        summary: summary,
        balances: balances,
      );
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: _message(error));
    }
    notifyListeners();
  }

  Future<void> setPeriod(String period) async {
    _state = _state.copyWith(period: period);
    notifyListeners();
    await load();
  }

  Future<void> setDate(DateTime date) async {
    _state = _state.copyWith(date: date);
    notifyListeners();
    await load();
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado";
  }
}

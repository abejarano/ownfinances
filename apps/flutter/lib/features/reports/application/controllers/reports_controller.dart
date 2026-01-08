import "package:flutter/material.dart";
import "package:ownfinances/core/infrastructure/api/api_exception.dart";
import "package:ownfinances/features/reports/application/state/reports_state.dart";
import "package:ownfinances/features/reports/domain/entities/report_balances.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";
import "package:ownfinances/features/reports/domain/repositories/reports_repository.dart";

class ReportsController extends ChangeNotifier {
  final ReportsRepository repository;
  ReportsState _state = ReportsState.initial();

  ReportsController(this.repository);

  ReportsState get state => _state;

  void applyImpactFromJson(Map<String, dynamic> impact) {
    final summaryRaw = impact["summary"];
    final balancesRaw = impact["balances"];
    final summary = summaryRaw is Map<String, dynamic>
        ? ReportSummary.fromJson(summaryRaw)
        : null;
    final balances = balancesRaw is Map<String, dynamic>
        ? ReportBalances.fromJson(balancesRaw)
        : null;
    applyImpact(summary: summary, balances: balances);
  }

  void applyImpact({ReportSummary? summary, ReportBalances? balances}) {
    if (summary == null && balances == null) return;
    _state = _state.copyWith(
      summary: summary ?? _state.summary,
      balances: balances ?? _state.balances,
    );
    notifyListeners();
  }

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final summary = await repository.summary(
        period: _state.period,
        date: _state.date,
      );
      final balances = await repository.balances(
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

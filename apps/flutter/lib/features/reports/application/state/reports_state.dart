import "package:ownfinances/features/reports/domain/entities/report_summary.dart";
import "package:ownfinances/features/reports/domain/entities/report_balances.dart";

class ReportsState {
  final bool isLoading;
  final ReportSummary? summary;
  final ReportBalances? balances;
  final String period;
  final DateTime date;
  final String? error;

  const ReportsState({
    required this.isLoading,
    required this.summary,
    required this.balances,
    required this.period,
    required this.date,
    this.error,
  });

  ReportsState copyWith({
    bool? isLoading,
    ReportSummary? summary,
    ReportBalances? balances,
    String? period,
    DateTime? date,
    String? error,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      balances: balances ?? this.balances,
      period: period ?? this.period,
      date: date ?? this.date,
      error: error,
    );
  }

  factory ReportsState.initial() {
    return ReportsState(
      isLoading: false,
      summary: null,
      balances: null,
      period: "monthly",
      date: DateTime.now(),
    );
  }
}

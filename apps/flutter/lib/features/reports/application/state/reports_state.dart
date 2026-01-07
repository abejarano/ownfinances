import "package:ownfinances/features/reports/domain/entities/report_summary.dart";

class ReportsState {
  final bool isLoading;
  final ReportSummary? summary;
  final String period;
  final DateTime date;
  final String? error;

  const ReportsState({
    required this.isLoading,
    required this.summary,
    required this.period,
    required this.date,
    this.error,
  });

  ReportsState copyWith({
    bool? isLoading,
    ReportSummary? summary,
    String? period,
    DateTime? date,
    String? error,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      period: period ?? this.period,
      date: date ?? this.date,
      error: error,
    );
  }

  factory ReportsState.initial() {
    return ReportsState(
      isLoading: false,
      summary: null,
      period: "monthly",
      date: DateTime.now(),
    );
  }
}

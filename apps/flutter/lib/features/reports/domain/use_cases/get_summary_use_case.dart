import "package:ownfinances/features/reports/domain/entities/report_summary.dart";
import "package:ownfinances/features/reports/domain/repositories/reports_repository.dart";

class GetSummaryUseCase {
  final ReportsRepository repository;

  GetSummaryUseCase(this.repository);

  Future<ReportSummary> execute({
    required String period,
    required DateTime date,
  }) {
    return repository.summary(period: period, date: date);
  }
}

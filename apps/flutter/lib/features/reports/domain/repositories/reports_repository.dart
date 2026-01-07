import "package:ownfinances/features/reports/domain/entities/report_summary.dart";

abstract class ReportsRepository {
  Future<ReportSummary> summary({
    required String period,
    required DateTime date,
  });
}

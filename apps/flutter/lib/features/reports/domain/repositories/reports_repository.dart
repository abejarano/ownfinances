import "package:ownfinances/features/reports/domain/entities/report_summary.dart";
import "package:ownfinances/features/reports/domain/entities/report_balances.dart";

abstract class ReportsRepository {
  Future<ReportSummary> summary({
    required String period,
    required DateTime date,
  });

  Future<ReportBalances> balances({
    required String period,
    required DateTime date,
  });
}

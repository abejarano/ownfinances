import "package:ownfinances/features/reports/data/datasources/reports_remote_data_source.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";
import "package:ownfinances/features/reports/domain/entities/report_balances.dart";
import "package:ownfinances/features/reports/domain/repositories/reports_repository.dart";

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remote;

  ReportsRepositoryImpl(this.remote);

  @override
  Future<ReportSummary> summary({
    required String period,
    required DateTime date,
  }) async {
    final payload = await remote.summary(period: period, date: date);
    return ReportSummary.fromJson(payload);
  }

  @override
  Future<ReportBalances> balances({
    required String period,
    required DateTime date,
  }) async {
    final payload = await remote.balances(period: period, date: date);
    return ReportBalances.fromJson(payload);
  }
}

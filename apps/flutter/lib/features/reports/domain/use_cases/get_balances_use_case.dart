import "package:ownfinances/features/reports/domain/entities/report_balances.dart";
import "package:ownfinances/features/reports/domain/repositories/reports_repository.dart";

class GetBalancesUseCase {
  final ReportsRepository repository;

  GetBalancesUseCase(this.repository);

  Future<ReportBalances> execute({
    required String period,
    required DateTime date,
  }) {
    return repository.balances(period: period, date: date);
  }
}

import "package:ownfinances/features/debts/data/datasources/debt_remote_data_source.dart";
import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/features/debts/domain/entities/debt_summary.dart";
import "package:ownfinances/features/debts/domain/entities/debt_overview.dart";
import "package:ownfinances/features/debts/domain/entities/debt_transaction.dart";
import "package:ownfinances/features/debts/domain/repositories/debt_repository.dart";

class DebtRepositoryImpl implements DebtRepository {
  final DebtRemoteDataSource remote;

  DebtRepositoryImpl(this.remote);

  @override
  Future<List<Debt>> list() async {
    final payload = await remote.list();
    final results = payload["results"] as List<dynamic>? ?? [];
    return results
        .map((item) => Debt.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Debt> create({
    required String name,
    required String type,
    String? linkedAccountId,
    String? paymentAccountId,
    String? currency,
    int? dueDay,
    double? minimumPayment,
    double? interestRateAnnual,
    double? initialBalance,
    bool? isActive,
  }) async {
    final payload = await remote.create({
      "name": name,
      "type": type,
      "linkedAccountId": linkedAccountId,
      "paymentAccountId": paymentAccountId,
      "currency": currency,
      "dueDay": dueDay,
      "minimumPayment": minimumPayment,
      "interestRateAnnual": interestRateAnnual,
      "initialBalance": initialBalance,
      "isActive": isActive,
    });
    return Debt.fromJson(payload["debt"] as Map<String, dynamic>);
  }

  @override
  Future<Debt> update(
    String id, {
    String? name,
    String? type,
    String? linkedAccountId,
    String? paymentAccountId,
    String? currency,
    int? dueDay,
    double? minimumPayment,
    double? interestRateAnnual,
    bool? isActive,
  }) async {
    final payload = await remote.update(id, {
      "name": name,
      "type": type,
      "linkedAccountId": linkedAccountId,
      "paymentAccountId": paymentAccountId,
      "currency": currency,
      "dueDay": dueDay,
      "minimumPayment": minimumPayment,
      "interestRateAnnual": interestRateAnnual,
      "isActive": isActive,
    });
    return Debt.fromJson(payload["debt"] as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) {
    return remote.delete(id);
  }

  @override
  Future<DebtSummary> summary(String id) async {
    final payload = await remote.summary(id);
    return DebtSummary.fromJson(payload);
  }

  @override
  Future<List<DebtTransaction>> history(String id, {String? month}) async {
    final payload = await remote.history(id, month: month);
    final results = payload["results"] as List<dynamic>? ?? [];
    return results
        .map((item) => DebtTransaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DebtOverview> getOverview() async {
    final payload = await remote.getOverview();
    return DebtOverview.fromJson(payload);
  }
}

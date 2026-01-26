import "package:ownfinances/features/debts/data/datasources/debt_remote_data_source.dart";
import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/features/debts/domain/entities/debt_summary.dart";
import "package:ownfinances/features/debts/domain/entities/debt_overview.dart";
import "package:ownfinances/features/debts/domain/entities/debt_transaction.dart";

class DebtRepository {
  final DebtRemoteDataSource remote;

  DebtRepository(this.remote);

  Future<List<Debt>> list() async {
    final payload = await remote.list();
    final results = payload["results"] as List<dynamic>? ?? [];
    return results
        .map((item) => Debt.fromJson(item as Map<String, dynamic>))
        .toList();
  }

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

  Future<void> delete(String id) {
    return remote.delete(id);
  }

  Future<DebtSummary> summary(String id, {DateTime? month}) async {
    final payload = await remote.summary(id, month: month);
    return DebtSummary.fromJson(payload);
  }

  Future<List<DebtTransaction>> history(String id, {String? month}) async {
    final payload = await remote.history(id, month: month);
    final results = payload["results"] as List<dynamic>? ?? [];
    return results
        .map((item) => DebtTransaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DebtOverview> getOverview() async {
    final payload = await remote.getOverview();
    return DebtOverview.fromJson(payload);
  }
}

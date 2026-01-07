import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/features/debts/domain/entities/debt_summary.dart";

abstract class DebtRepository {
  Future<List<Debt>> list();
  Future<Debt> create({
    required String name,
    required String type,
    String? currency,
    int? dueDay,
    double? minimumPayment,
    double? interestRateAnnual,
    bool? isActive,
  });
  Future<Debt> update(
    String id, {
    String? name,
    String? type,
    String? currency,
    int? dueDay,
    double? minimumPayment,
    double? interestRateAnnual,
    bool? isActive,
  });
  Future<void> delete(String id);
  Future<DebtSummary> summary(String id);
}

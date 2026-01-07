import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/features/debts/domain/repositories/debt_repository.dart";

class UpdateDebtUseCase {
  final DebtRepository repository;

  UpdateDebtUseCase(this.repository);

  Future<Debt> execute({
    required String id,
    String? name,
    String? type,
    String? currency,
    int? dueDay,
    double? minimumPayment,
    double? interestRateAnnual,
    bool? isActive,
  }) {
    return repository.update(
      id,
      name: name,
      type: type,
      currency: currency,
      dueDay: dueDay,
      minimumPayment: minimumPayment,
      interestRateAnnual: interestRateAnnual,
      isActive: isActive,
    );
  }
}

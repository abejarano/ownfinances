import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/features/debts/domain/repositories/debt_repository.dart";

class CreateDebtUseCase {
  final DebtRepository repository;

  CreateDebtUseCase(this.repository);

  Future<Debt> execute({
    required String name,
    required String type,
    String? currency,
    int? dueDay,
    double? minimumPayment,
    double? interestRateAnnual,
    bool? isActive,
  }) {
    return repository.create(
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

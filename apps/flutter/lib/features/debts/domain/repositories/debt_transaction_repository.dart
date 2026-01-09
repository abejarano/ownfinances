import "package:ownfinances/features/debts/domain/entities/debt_transaction.dart";

abstract class DebtTransactionRepository {
  Future<DebtTransaction> create({
    required String debtId,
    required DateTime date,
    required String type,
    required double amount,
    String? accountId,
    String? categoryId,
    String? note,
  });
}

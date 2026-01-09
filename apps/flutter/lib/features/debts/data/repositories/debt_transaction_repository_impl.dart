import "package:ownfinances/features/debts/data/datasources/debt_transaction_remote_data_source.dart";
import "package:ownfinances/features/debts/domain/entities/debt_transaction.dart";
import "package:ownfinances/features/debts/domain/repositories/debt_transaction_repository.dart";

class DebtTransactionRepositoryImpl implements DebtTransactionRepository {
  final DebtTransactionRemoteDataSource remote;

  DebtTransactionRepositoryImpl(this.remote);

  @override
  Future<DebtTransaction> create({
    required String debtId,
    required DateTime date,
    required String type,
    required double amount,
    String? accountId,
    String? categoryId,
    String? note,
  }) async {
    final payload = await remote.create({
      "debtId": debtId,
      "date": date.toIso8601String(),
      "type": type,
      "amount": amount,
      "accountId": accountId,
      "categoryId": categoryId,
      "note": note,
    });
    return DebtTransaction.fromJson(payload);
  }
}

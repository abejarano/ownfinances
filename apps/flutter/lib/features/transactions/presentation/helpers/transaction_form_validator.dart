import "package:ownfinances/features/debts/domain/entities/debt.dart";

class TransactionFormValidator {
  TransactionFormValidator._();

  static bool validate({
    required String type,
    required double amount,
    required String? fromAccountId,
    required String? toAccountId,
    required String? categoryId,
    required Debt? linkedDebt,
    required String? debtId,
    required bool isConversionMode,
    required double? destinationAmount,
  }) {
    if (debtId != null) {
      return _validateDebtMode(amount: amount, fromAccountId: fromAccountId);
    }

    if (type == "transfer") {
      return _validateTransfer(
        amount: amount,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        linkedDebt: linkedDebt,
        isConversionMode: isConversionMode,
        destinationAmount: destinationAmount,
      );
    }

    return _validateIncomeOrExpense(
      type: type,
      amount: amount,
      categoryId: categoryId,
      linkedDebt: linkedDebt,
    );
  }

  static bool _validateDebtMode({
    required double amount,
    required String? fromAccountId,
  }) {
    if (fromAccountId == null) return false;
    if (amount <= 0) return false;
    return true;
  }

  static bool _validateTransfer({
    required double amount,
    required String? fromAccountId,
    required String? toAccountId,
    required Debt? linkedDebt,
    required bool isConversionMode,
    required double? destinationAmount,
  }) {
    if (fromAccountId == null || toAccountId == null) return false;
    if (fromAccountId == toAccountId) return false;
    if (linkedDebt != null) return false;
    if (amount <= 0) return false;
    if (isConversionMode && (destinationAmount == null || destinationAmount <= 0)) {
      return false;
    }
    return true;
  }

  static bool _validateIncomeOrExpense({
    required String type,
    required double amount,
    required String? categoryId,
    required Debt? linkedDebt,
  }) {
    if (amount <= 0) return false;
    if (type == "expense" && linkedDebt != null && categoryId == null) {
      return false;
    }
    return true;
  }
}

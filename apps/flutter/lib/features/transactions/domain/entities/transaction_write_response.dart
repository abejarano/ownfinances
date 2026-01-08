import "package:ownfinances/features/transactions/domain/entities/transaction.dart";

class TransactionWriteResponse {
  final Transaction transaction;
  final Map<String, dynamic>? impact;

  const TransactionWriteResponse({
    required this.transaction,
    required this.impact,
  });

  factory TransactionWriteResponse.fromJson(Map<String, dynamic> json) {
    return TransactionWriteResponse(
      transaction: Transaction.fromJson(json),
      impact: json["impact"] as Map<String, dynamic>?,
    );
  }
}


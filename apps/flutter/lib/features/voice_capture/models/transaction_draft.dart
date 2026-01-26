class TransactionDraft {
  final double? amount;
  final String? fromAccountId;
  final DateTime? date;
  final String? categoryId;

  const TransactionDraft({
    this.amount,
    this.fromAccountId,
    this.date,
    this.categoryId,
  });

  TransactionDraft copyWith({
    double? amount,
    String? fromAccountId,
    DateTime? date,
    String? categoryId,
  }) {
    return TransactionDraft(
      amount: amount ?? this.amount,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  TransactionDraft reset() => const TransactionDraft();

  bool get isComplete =>
      amount != null && fromAccountId != null && categoryId != null;
}

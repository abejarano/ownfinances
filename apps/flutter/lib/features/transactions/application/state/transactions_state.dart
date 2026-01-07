import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";

class TransactionsState {
  final bool isLoading;
  final List<Transaction> items;
  final TransactionFilters filters;
  final String? error;
  final String? lastCategoryId;
  final String? lastFromAccountId;
  final String? lastToAccountId;

  const TransactionsState({
    required this.isLoading,
    required this.items,
    required this.filters,
    this.error,
    this.lastCategoryId,
    this.lastFromAccountId,
    this.lastToAccountId,
  });

  TransactionsState copyWith({
    bool? isLoading,
    List<Transaction>? items,
    TransactionFilters? filters,
    String? error,
    String? lastCategoryId,
    String? lastFromAccountId,
    String? lastToAccountId,
  }) {
    return TransactionsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      filters: filters ?? this.filters,
      error: error,
      lastCategoryId: lastCategoryId ?? this.lastCategoryId,
      lastFromAccountId: lastFromAccountId ?? this.lastFromAccountId,
      lastToAccountId: lastToAccountId ?? this.lastToAccountId,
    );
  }

  factory TransactionsState.initial() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return TransactionsState(
      isLoading: false,
      items: const [],
      filters: TransactionFilters(dateFrom: start, dateTo: end),
    );
  }
}

import 'package:ownfinances/features/transactions/domain/entities/transaction.dart';

class PendingTransactionsState {
  final bool isLoading;
  final String? error;
  final List<Transaction> items;

  const PendingTransactionsState({
    required this.isLoading,
    this.error,
    required this.items,
  });

  factory PendingTransactionsState.initial() {
    return const PendingTransactionsState(isLoading: false, items: []);
  }

  PendingTransactionsState copyWith({
    bool? isLoading,
    String? error,
    List<Transaction>? items,
  }) {
    return PendingTransactionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
    );
  }
}

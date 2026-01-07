import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/features/debts/domain/entities/debt_summary.dart";

class DebtsState {
  final List<Debt> items;
  final Map<String, DebtSummary> summaries;
  final bool isLoading;
  final String? error;
  final String? lastAccountId;

  const DebtsState({
    required this.items,
    required this.summaries,
    required this.isLoading,
    required this.error,
    required this.lastAccountId,
  });

  DebtsState copyWith({
    List<Debt>? items,
    Map<String, DebtSummary>? summaries,
    bool? isLoading,
    String? error,
    String? lastAccountId,
  }) {
    return DebtsState(
      items: items ?? this.items,
      summaries: summaries ?? this.summaries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastAccountId: lastAccountId ?? this.lastAccountId,
    );
  }

  static DebtsState initial() {
    return const DebtsState(
      items: [],
      summaries: {},
      isLoading: false,
      error: null,
      lastAccountId: null,
    );
  }
}

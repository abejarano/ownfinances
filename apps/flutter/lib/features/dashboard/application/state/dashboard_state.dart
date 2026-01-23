import 'package:ownfinances/features/transactions/domain/entities/transaction.dart';
import 'package:ownfinances/features/accounts/domain/entities/account.dart';
import 'package:ownfinances/features/debts/domain/entities/debt.dart';

class DashboardAccountSummary {
  final Account account;
  final double income;
  final double expense;
  final double balance; // Calculated from movements this month
  final double? totalBalance; // Fetched from Reports (Total history)
  final Debt? linkedDebt; // Fetched from Debt Module
  final bool hasMovements;

  const DashboardAccountSummary({
    required this.account,
    required this.income,
    required this.expense,
    required this.balance,
    this.totalBalance,
    this.linkedDebt,
    required this.hasMovements,
  });
}

class DashboardState {
  final bool isLoading;
  final String? error;
  final DateTime date; // Selected month

  // Data
  final List<Transaction> transactions;
  final List<Account> accounts;

  // Computed
  final List<DashboardAccountSummary> mainAccounts;
  final List<DashboardAccountSummary> otherAccounts;
  final List<Debt> activeDebts;
  final bool hasPriorityDebt; // If any debt is due in <= 7 days
  final double totalPaidDebts; // [NEW] Total paid to debts this month

  // Primary Currency Configuration
  final String primaryCurrency;

  const DashboardState({
    required this.isLoading,
    this.error,
    required this.date,
    required this.transactions,
    required this.accounts,
    required this.mainAccounts,
    required this.otherAccounts,
    required this.activeDebts,
    required this.hasPriorityDebt,
    required this.totalPaidDebts,

    required this.primaryCurrency,
  });

  factory DashboardState.initial() {
    return DashboardState(
      isLoading: false,
      date: DateTime.now(),
      transactions: [],
      accounts: [],
      mainAccounts: [],
      otherAccounts: [],
      activeDebts: [],
      hasPriorityDebt: false,
      totalPaidDebts: 0.0,

      primaryCurrency: "BRL", // Default
    );
  }

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    DateTime? date,
    List<Transaction>? transactions,
    List<Account>? accounts,
    List<DashboardAccountSummary>? mainAccounts,
    List<DashboardAccountSummary>? otherAccounts,
    List<Debt>? activeDebts,
    bool? hasPriorityDebt,
    double? totalPaidDebts,

    String? primaryCurrency,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      date: date ?? this.date,
      transactions: transactions ?? this.transactions,
      accounts: accounts ?? this.accounts,
      mainAccounts: mainAccounts ?? this.mainAccounts,
      otherAccounts: otherAccounts ?? this.otherAccounts,
      activeDebts: activeDebts ?? this.activeDebts,
      hasPriorityDebt: hasPriorityDebt ?? this.hasPriorityDebt,
      totalPaidDebts: totalPaidDebts ?? this.totalPaidDebts,

      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
    );
  }
}

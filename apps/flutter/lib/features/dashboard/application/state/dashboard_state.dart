import 'package:ownfinances/features/transactions/domain/entities/transaction.dart';
import 'package:ownfinances/features/accounts/domain/entities/account.dart';

class DashboardAccountSummary {
  final Account account;
  final double income;
  final double expense;
  final double balance; // Calculated from movements this month
  final bool hasMovements;

  const DashboardAccountSummary({
    required this.account,
    required this.income,
    required this.expense,
    required this.balance,
    required this.hasMovements,
  });
}

class DashboardCurrencySummary {
  final String currency;
  final double
  balance; // Net for the month or total balance? PO said "USDT +18.000", implying net change or total.
  // Context: "Outras moedas: USDT +18.000". Likely month performance or total net worth?
  // "Resumo do mês" implies month performance. But usually "Outras moedas" implies holding.
  // Re-reading PO: "Outras moedas: USDT +18.000 • EUR +120" -> "Resumen por moneda, sin convertir".
  // Given it's a dashboard, usually it's month flow, but "18.000" sounds like total.
  // However, let's stick to Month Scope for consistency with the rest of the dashboard unless specified otherwise.
  // Wait, "Resumo do mês" is the top card.
  // Actually, let's use the Sum of Net Income-Expense for the month for now.

  const DashboardCurrencySummary({
    required this.currency,
    required this.balance,
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
  final List<DashboardAccountSummary> accountSummaries;
  final List<DashboardCurrencySummary> otherCurrencies;

  // Main Currency Summary (BRL)
  final double mainCurrencyIncome;
  final double mainCurrencyExpense;
  final double mainCurrencyNet;
  final bool hasMainCurrencyMovements;

  // Primary Currency Configuration
  final String primaryCurrency;
  final bool hasPrimaryCurrencyAccounts;

  const DashboardState({
    required this.isLoading,
    this.error,
    required this.date,
    required this.transactions,
    required this.accounts,
    required this.accountSummaries,
    required this.otherCurrencies,
    required this.mainCurrencyIncome,
    required this.mainCurrencyExpense,
    required this.mainCurrencyNet,
    required this.hasMainCurrencyMovements,
    required this.primaryCurrency,
    required this.hasPrimaryCurrencyAccounts,
  });

  factory DashboardState.initial() {
    return DashboardState(
      isLoading: false,
      date: DateTime.now(),
      transactions: [],
      accounts: [],
      accountSummaries: [],
      otherCurrencies: [],
      mainCurrencyIncome: 0,
      mainCurrencyExpense: 0,
      mainCurrencyNet: 0,
      hasMainCurrencyMovements: false,
      primaryCurrency: "BRL", // Default
      hasPrimaryCurrencyAccounts: false,
    );
  }

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    DateTime? date,
    List<Transaction>? transactions,
    List<Account>? accounts,
    List<DashboardAccountSummary>? accountSummaries,
    List<DashboardCurrencySummary>? otherCurrencies,
    double? mainCurrencyIncome,
    double? mainCurrencyExpense,
    double? mainCurrencyNet,
    bool? hasMainCurrencyMovements,
    String? primaryCurrency,
    bool? hasPrimaryCurrencyAccounts,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      date: date ?? this.date,
      transactions: transactions ?? this.transactions,
      accounts: accounts ?? this.accounts,
      accountSummaries: accountSummaries ?? this.accountSummaries,
      otherCurrencies: otherCurrencies ?? this.otherCurrencies,
      mainCurrencyIncome: mainCurrencyIncome ?? this.mainCurrencyIncome,
      mainCurrencyExpense: mainCurrencyExpense ?? this.mainCurrencyExpense,
      mainCurrencyNet: mainCurrencyNet ?? this.mainCurrencyNet,
      hasMainCurrencyMovements:
          hasMainCurrencyMovements ?? this.hasMainCurrencyMovements,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      hasPrimaryCurrencyAccounts:
          hasPrimaryCurrencyAccounts ?? this.hasPrimaryCurrencyAccounts,
    );
  }
}

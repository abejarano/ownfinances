import 'package:ownfinances/features/accounts/domain/entities/account.dart';

class CategoryExpenseSummary {
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final double amount;
  final List<CurrencyFlowSummary> otherCurrencies;

  CategoryExpenseSummary({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.amount,
    this.otherCurrencies = const [],
  });
}

class AccountFlowSummary {
  final Account account;
  final double income;
  final double expense;
  final double net;

  AccountFlowSummary({
    required this.account,
    required this.income,
    required this.expense,
    required this.net,
  });
}

class CurrencyFlowSummary {
  final String currency;
  final double income;
  final double expense;
  final double net;

  CurrencyFlowSummary({
    required this.currency,
    required this.income,
    required this.expense,
    required this.net,
  });
}

class MonthSummaryState {
  final bool isLoading;
  final String? error;
  final DateTime date;
  final String primaryCurrency;

  // Tab 1: Primary Currency (Expenses Only)
  final List<CategoryExpenseSummary> categoryExpenses;
  final double totalPrimaryExpense;
  final bool hasPrimaryMovements;
  final double
  totalPrimaryIncome; // Optional, might be used for footer if requested

  // Tab 2: By Account
  final List<AccountFlowSummary> accountFlows;

  // Tab 3: Other Currencies
  final List<CurrencyFlowSummary> currencyFlows;

  // Footer: Global totals for other currencies (Tab 1 footer)
  final List<CurrencyFlowSummary> otherCurrencyTotals;

  MonthSummaryState({
    required this.isLoading,
    this.error,
    required this.date,
    required this.primaryCurrency,
    required this.categoryExpenses,
    required this.totalPrimaryExpense,
    required this.hasPrimaryMovements,
    required this.totalPrimaryIncome,
    required this.accountFlows,
    required this.currencyFlows,
    required this.otherCurrencyTotals,
  });

  factory MonthSummaryState.initial() {
    return MonthSummaryState(
      isLoading: false,
      date: DateTime.now(),
      primaryCurrency: 'BRL',
      categoryExpenses: [],
      totalPrimaryExpense: 0,
      hasPrimaryMovements: false,
      totalPrimaryIncome: 0,
      accountFlows: [],
      currencyFlows: [],
      otherCurrencyTotals: [],
    );
  }

  MonthSummaryState copyWith({
    bool? isLoading,
    String? error,
    DateTime? date,
    String? primaryCurrency,
    List<CategoryExpenseSummary>? categoryExpenses,
    double? totalPrimaryExpense,
    bool? hasPrimaryMovements,
    double? totalPrimaryIncome,
    List<AccountFlowSummary>? accountFlows,
    List<CurrencyFlowSummary>? currencyFlows,
    List<CurrencyFlowSummary>? otherCurrencyTotals,
  }) {
    return MonthSummaryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      date: date ?? this.date,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      categoryExpenses: categoryExpenses ?? this.categoryExpenses,
      totalPrimaryExpense: totalPrimaryExpense ?? this.totalPrimaryExpense,
      hasPrimaryMovements: hasPrimaryMovements ?? this.hasPrimaryMovements,
      totalPrimaryIncome: totalPrimaryIncome ?? this.totalPrimaryIncome,
      accountFlows: accountFlows ?? this.accountFlows,
      currencyFlows: currencyFlows ?? this.currencyFlows,
      otherCurrencyTotals: otherCurrencyTotals ?? this.otherCurrencyTotals,
    );
  }
}

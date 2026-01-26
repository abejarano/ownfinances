import 'package:flutter/material.dart';
import 'package:ownfinances/features/transactions/domain/entities/transaction_filters.dart';
import 'package:ownfinances/core/infrastructure/api/api_exception.dart';
import 'package:ownfinances/features/accounts/data/repositories/account_repository.dart';
import 'package:ownfinances/features/categories/data/repositories/category_repository.dart';
import 'package:ownfinances/features/month_summary/application/state/month_summary_state.dart';
import 'package:ownfinances/features/settings/application/controllers/settings_controller.dart';
import 'package:ownfinances/features/transactions/data/repositories/transaction_repository.dart';
import 'package:ownfinances/features/transactions/domain/entities/transaction.dart';
import 'package:ownfinances/features/accounts/domain/entities/account.dart'; // Import Account

class MonthSummaryController extends ChangeNotifier {
  final TransactionRepository transactionsRepository;
  final AccountRepository accountRepository;
  final CategoryRepository categoriesRepository; // Fixed Name
  final SettingsController settingsController;

  MonthSummaryState _state = MonthSummaryState.initial();
  MonthSummaryState get state => _state;

  void reset() {
    _state = MonthSummaryState.initial();
    notifyListeners();
  }

  MonthSummaryController({
    required this.transactionsRepository,
    required this.accountRepository,
    required this.categoriesRepository,
    required this.settingsController,
  });

  Future<void> load({DateTime? date}) async {
    final targetDate = date ?? _state.date;

    // If only refreshing logic (no date change), keep loading minimal if possible, but here we do full reload.
    _state = _state.copyWith(isLoading: true, date: targetDate, error: null);
    notifyListeners();

    try {
      final primaryCurrency = settingsController.primaryCurrency;

      // 1. Fetch Data
      final start = DateTime(targetDate.year, targetDate.month, 1);
      final end = DateTime(
        targetDate.year,
        targetDate.month + 1,
        0,
        23,
        59,
        59,
      );

      final transactionsFuture = transactionsRepository.list(
        filters: TransactionFilters(dateFrom: start, dateTo: end, limit: 1000),
      );

      final accountsFuture = accountRepository.list(isActive: true);
      final categoriesFuture = categoriesRepository.list();

      final results = await Future.wait([
        transactionsFuture,
        accountsFuture,
        categoriesFuture,
      ]);

      final transactions = (results[0] as dynamic).results as List<Transaction>;
      final accounts = (results[1] as dynamic).results as List<Account>;
      final categories = (results[2] as dynamic).results as dynamic;

      final categoryMap = {for (var c in categories) c.id: c};
      // remove unused accountMap

      // --- Logic: Tab 1 (Primary Currency Expenses + Multi-Currency Chips) ---
      final categoryExpenseMap = <String, double>{};
      final categoryOtherCurrenciesMap = <String, Map<String, double>>{};
      final globalOtherCurrenciesMap = <String, double>{};

      double totalPrimaryExpense = 0;
      double totalPrimaryIncome = 0;
      bool hasPrimaryMovements = false;

      for (final tx in transactions) {
        if (tx.type == 'transfer')
          continue; // Don't count transfers in category list

        // Primary Currency Logic
        if (tx.currency == primaryCurrency) {
          hasPrimaryMovements = true;

          if (tx.type == 'income') {
            totalPrimaryIncome += tx.amount.abs();
          } else if (tx.type == 'expense') {
            final amount = tx.amount.abs();
            final catId = tx.categoryId ?? 'uncategorized';
            categoryExpenseMap[catId] =
                (categoryExpenseMap[catId] ?? 0) + amount;
            totalPrimaryExpense += amount;
          }
        }
        // Secondary Currency Logic (Expenses Only for Category List)
        else if (tx.type == 'expense') {
          final amount = tx.amount.abs();
          final catId = tx.categoryId ?? 'uncategorized';
          final currency = tx.currency;

          // Per Category
          if (!categoryOtherCurrenciesMap.containsKey(catId)) {
            categoryOtherCurrenciesMap[catId] = {};
          }
          final currentCatVal =
              categoryOtherCurrenciesMap[catId]![currency] ?? 0;
          categoryOtherCurrenciesMap[catId]![currency] = currentCatVal + amount;

          // Global Footer
          final currentGlobalVal = globalOtherCurrenciesMap[currency] ?? 0;
          globalOtherCurrenciesMap[currency] = currentGlobalVal + amount;
        }
      }

      final categoryExpenses = categoryExpenseMap.entries.map((e) {
        final catId = e.key;
        final amount = e.value;
        String name = 'Sem categoria';
        String? icon;
        String? color;

        if (catId != 'uncategorized' && categoryMap.containsKey(catId)) {
          final cat = categoryMap[catId];
          name = cat.name;
          icon = cat.icon;
          color = cat.color;
        }

        // Process other currencies for this category
        final otherCurrencies = <CurrencyFlowSummary>[];
        if (categoryOtherCurrenciesMap.containsKey(catId)) {
          categoryOtherCurrenciesMap[catId]!.forEach((currency, amount) {
            otherCurrencies.add(
              CurrencyFlowSummary(
                currency: currency,
                income: 0,
                expense: amount,
                net: -amount,
              ),
            );
          });
        }

        return CategoryExpenseSummary(
          categoryId: catId,
          categoryName: name,
          categoryIcon: icon,
          categoryColor: color,
          amount: amount,
          otherCurrencies: otherCurrencies,
        );
      }).toList();

      // Also include categories that ONLY have secondary currencies (but 0 primary)
      // This is important for Case 2 & 3: User might have 0 BRL but 10 USD in "Cultura"
      categoryOtherCurrenciesMap.forEach((catId, currencyMap) {
        if (!categoryExpenseMap.containsKey(catId)) {
          String name = 'Sem categoria';
          String? icon;
          String? color;

          if (catId != 'uncategorized' && categoryMap.containsKey(catId)) {
            final cat = categoryMap[catId];
            name = cat.name;
            icon = cat.icon;
            color = cat.color;
          }

          final otherCurrencies = <CurrencyFlowSummary>[];
          currencyMap.forEach((currency, amount) {
            otherCurrencies.add(
              CurrencyFlowSummary(
                currency: currency,
                income: 0,
                expense: amount,
                net: -amount,
              ),
            );
          });

          categoryExpenses.add(
            CategoryExpenseSummary(
              categoryId: catId,
              categoryName: name,
              categoryIcon: icon,
              categoryColor: color,
              amount: 0, // 0 Primary
              otherCurrencies: otherCurrencies,
            ),
          );
        }
      });

      // Prepare Global Footer Totals
      final otherCurrencyTotals = <CurrencyFlowSummary>[];
      globalOtherCurrenciesMap.forEach((currency, amount) {
        otherCurrencyTotals.add(
          CurrencyFlowSummary(
            currency: currency,
            income: 0,
            expense: amount,
            net: -amount,
          ),
        );
      });

      categoryExpenses.sort((a, b) => b.amount.compareTo(a.amount));

      // --- Logic: Tab 2 (By Account) ---
      final accountSummaries = <AccountFlowSummary>[];

      for (final account in accounts) {
        double income = 0;
        double expense = 0;

        for (final tx in transactions) {
          final absAmount = tx.amount.abs();

          // Check Outflow (From Account)
          if (tx.fromAccountId == account.id) {
            expense += absAmount;
          }

          // Check Inflow (To Account)
          if (tx.toAccountId == account.id) {
            if (account.type == 'credit_card' || account.type == 'debt') {
              final inflow = tx.destinationAmount ?? absAmount;
              income += inflow;
            } else {
              final inflow = tx.destinationAmount ?? absAmount;
              income += inflow;
            }
          }
        }

        accountSummaries.add(
          AccountFlowSummary(
            // Fixed: push -> add
            account: account,
            income: income,
            expense: expense,
            net: income - expense,
          ),
        );
      }

      // --- Logic: Tab 3 (Other Currencies) ---
      final realCurrencyMap = <String, CurrencyFlowSummary>{};
      final accountMap = {for (var a in accounts) a.id: a};

      void addFlow(String currency, double income, double expense) {
        if (currency == primaryCurrency) return;

        final current =
            realCurrencyMap[currency] ??
            CurrencyFlowSummary(
              currency: currency,
              income: 0,
              expense: 0,
              net: 0,
            );

        realCurrencyMap[currency] = CurrencyFlowSummary(
          currency: currency,
          income: current.income + income,
          expense: current.expense + expense,
          net: (current.income + income) - (current.expense + expense),
        );
      }

      for (final tx in transactions) {
        // Handle Source Side
        if (tx.type == 'income') {
          addFlow(tx.currency, tx.amount.abs(), 0);
        } else if (tx.type == 'expense') {
          addFlow(tx.currency, 0, tx.amount.abs());
        } else if (tx.type == 'transfer') {
          // Outflow from Source Currency (e.g. USDT -> BRL)
          addFlow(tx.currency, 0, tx.amount.abs());

          // Inflow to Destination Currency (e.g. BRL -> USD)
          if (tx.toAccountId != null) {
            final toAccount = accountMap[tx.toAccountId];
            if (toAccount != null) {
              final destAmount = tx.destinationAmount ?? tx.amount.abs();
              addFlow(toAccount.currency, destAmount, 0);
            }
          }
        }
      }

      final currencyFlows = realCurrencyMap.values.toList();

      _state = _state.copyWith(
        isLoading: false,
        primaryCurrency: primaryCurrency,
        categoryExpenses: categoryExpenses,
        totalPrimaryExpense: totalPrimaryExpense,
        hasPrimaryMovements: hasPrimaryMovements,
        totalPrimaryIncome: totalPrimaryIncome,
        accountFlows: accountSummaries,
        currencyFlows: currencyFlows,
        otherCurrencyTotals: otherCurrencyTotals,
      );
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: _message(e));
    }
    notifyListeners();
  }

  Future<void> setDate(DateTime date) async {
    await load(date: date);
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return "Erro inesperado";
  }
}

import 'package:flutter/material.dart';
import "package:ownfinances/features/transactions/domain/entities/transaction_filters.dart";
import 'package:ownfinances/core/infrastructure/api/api_exception.dart';
import 'package:ownfinances/features/accounts/domain/entities/account.dart';
import 'package:ownfinances/features/accounts/data/repositories/account_repository.dart';
import 'package:ownfinances/features/dashboard/application/state/dashboard_state.dart';
import 'package:ownfinances/features/transactions/domain/entities/transaction.dart';
import 'package:ownfinances/features/transactions/data/repositories/transaction_repository.dart';

import 'package:ownfinances/features/settings/application/controllers/settings_controller.dart';

class DashboardController extends ChangeNotifier {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;
  final SettingsController settingsController;

  DashboardState _state = DashboardState.initial();

  DashboardController(
    this.transactionRepository,
    this.accountRepository,
    this.settingsController,
  ) {
    settingsController.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    settingsController.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    // Reload if primary currency changes
    // Or just re-calculate if data is already there?
    // We need to re-fetch? Aggregation depends on currency value.
    // If we just re-calc, we save network.
    // But load() fetches limits/filters?
    // Aggregation is purely local.
    // So let's just trigger load() to be safe or re-aggregate logic?
    // Given load() fetches logic, let's just call load() for simplicity.
    load();
  }

  DashboardState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      // 1. Fetch Accounts to know currencies
      final accountsResult = await accountRepository.list(
        isActive: null,
      ); // Fetch all to handle ref to closed accounts
      final accounts = accountsResult.results;

      // 2. Fetch Transactions for the month (pagination loop or large limit)
      // For MVP/Performance, let's try fetching up to 1000. If more, we might need a different strategy.
      // But for personal finance, >1000 tx/month is rare.
      final startOfMonth = DateTime(_state.date.year, _state.date.month, 1);
      final endOfMonth = DateTime(
        _state.date.year,
        _state.date.month + 1,
        0,
        23,
        59,
        59,
      );

      final txResult = await transactionRepository.list(
        filters: TransactionFilters(
          dateFrom: startOfMonth,
          dateTo: endOfMonth,
          limit: 1000,
        ),
      );
      final transactions = txResult.results;

      // 3. Aggregate Data
      _calculateAggregates(accounts, transactions);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : "Erro ao carregar dashboard",
      );
    }
    notifyListeners();
  }

  Future<void> setMonth(DateTime date) async {
    if (date.year == _state.date.year && date.month == _state.date.month)
      return;
    _state = _state.copyWith(date: date);
    notifyListeners();
    await load();
  }

  void _calculateAggregates(
    List<Account> accounts,
    List<Transaction> transactions,
  ) {
    // --- Rule 2: Month Summary (Dynamic Primary Currency) ---
    final primaryCurrency = settingsController.primaryCurrency;

    double mainIncome = 0;
    double mainExpense = 0;
    bool hasMainMovements = false;

    // Check if user has accounts in primary currency (for State C)
    final hasPrimaryCurrencyAccounts = accounts.any(
      (a) => a.currency == primaryCurrency && a.isActive,
    );

    // --- Rule 3: Account Carousel ---
    final accountSummariesMap = <String, DashboardAccountSummary>{};

    // Initialize summaries for all active accounts (even if no movements)
    for (final account in accounts) {
      if (account.isActive) {
        accountSummariesMap[account.id] = DashboardAccountSummary(
          account: account,
          income: 0,
          expense: 0,
          balance:
              0, // This balances is "Net Flow" for the month, NOT total account balance.
          // PO said: "Entradas / Saídas / Saldo (do mês)" implicitly.
          hasMovements: false,
        );
      }
    }

    // Process Transactions
    for (final tx in transactions) {
      // Skip transfers for Income/Expense totals to avoid double counting?
      // Usually Dashboard Summary sums actual Income/Expense. Transfers are neutral or handled separately.
      // However, "Resumo do mês" usually tracks Cash Flow.
      // If I transfer BRL -> USDT, BRL has Expense (Transfer Out), USDT has Income (Transfer In).
      // Let's stick to: Income = Type Income, Expense = Type Expense.
      // Transfers: usually excluded from "Spending" reports, but for "Account Flow", they matter.
      // PO Req: "Entradas / Saídas / Saldo".

      final absAmount = tx.amount.abs();

      // 1. Identify Account
      // Transactions have fromAccountId (expense/transfer-out) and/or toAccountId (income/transfer-in).
      // Income tx: toAccountId
      // Expense tx: fromAccountId
      // Transfer tx: fromAccountId AND toAccountId

      // Handle Main Currency Summary
      // Rule 1: Include Transfers if they affect Main Currency.

      // Case A: Standard Income/Expense in Main Currency
      if (tx.currency == primaryCurrency && tx.type != 'transfer') {
        if (tx.type == 'income') {
          mainIncome += absAmount;
          hasMainMovements = true;
        } else if (tx.type == 'expense') {
          mainExpense += absAmount;
          hasMainMovements = true;
        }
      }

      // Case B: Transfers involving Main Currency
      if (tx.type == 'transfer') {
        // Outflow from Main Currency
        // We need to check the Source Account Currency.
        // Ideally we have account map.
        // But here we can check if tx.currency (which is usually source currency) matches primary.
        // OR better: Check if the Account ID belongs to a Primary Currency Account.

        // Check Outflow Side
        if (tx.fromAccountId != null) {
          // Actually we have the full list `accounts`.
          // Let's find it.
          try {
            final fromAcc = accounts.firstWhere(
              (a) => a.id == tx.fromAccountId,
            );
            if (fromAcc.currency == primaryCurrency) {
              mainExpense += absAmount;
              hasMainMovements = true;
            }
          } catch (_) {}
        }

        // Check Inflow Side
        if (tx.toAccountId != null) {
          try {
            final toAcc = accounts.firstWhere((a) => a.id == tx.toAccountId);
            if (toAcc.currency == primaryCurrency) {
              // Use destinationAmount if avail, else amount
              final inflow = tx.destinationAmount ?? absAmount;
              mainIncome += inflow;
              hasMainMovements = true;
            }
          } catch (_) {}
        }
      }

      // Handle Account Summaries
      // A transaction can affect up to 2 accounts (transfer).

      if (tx.type == 'expense' ||
          (tx.type == 'transfer' && tx.fromAccountId != null)) {
        final accId = tx.fromAccountId!;
        if (accountSummariesMap.containsKey(accId)) {
          final current = accountSummariesMap[accId]!;
          accountSummariesMap[accId] = DashboardAccountSummary(
            account: current.account,
            income: current.income,
            expense: current.expense + absAmount,
            balance: current.balance - absAmount,
            hasMovements: true,
          );
        }
      }

      if (tx.type == 'income' ||
          (tx.type == 'transfer' && tx.toAccountId != null)) {
        final accId = tx.toAccountId!;
        if (accountSummariesMap.containsKey(accId)) {
          final current = accountSummariesMap[accId]!;

          // For transfers, use destinationAmount if available (for multi-currency).
          // Otherwise fall back to amount.
          final inflowAmount =
              (tx.type == 'transfer' && tx.destinationAmount != null)
              ? tx.destinationAmount!
              : absAmount;

          accountSummariesMap[accId] = DashboardAccountSummary(
            account: current.account,
            income: current.income + inflowAmount,
            expense: current.expense,
            balance: current.balance + inflowAmount,
            hasMovements: true,
          );
        }
      }
    }

    final mainNet = mainIncome - mainExpense;

    // Sorting Account Summaries: Active first, then inactive
    final sortedAccountSummaries = accountSummariesMap.values.toList()
      ..sort((a, b) {
        if (a.hasMovements && !b.hasMovements) return -1;
        if (!a.hasMovements && b.hasMovements) return 1;
        return a.account.name.compareTo(b.account.name);
      });

    // --- Rule 4: Other Currencies ---
    // Group totals by currency (excluding Primary)
    // We can aggregate from the account summaries to be safe.
    final otherCurrencyMap = <String, double>{};
    for (final summary in sortedAccountSummaries) {
      if (summary.account.currency == primaryCurrency) continue;

      final currency = summary.account.currency;
      final net = summary.balance;
      otherCurrencyMap[currency] = (otherCurrencyMap[currency] ?? 0) + net;
    }

    final otherCurrencies = otherCurrencyMap.entries
        .map((e) => DashboardCurrencySummary(currency: e.key, balance: e.value))
        .toList();

    _state = _state.copyWith(
      isLoading: false,
      transactions: transactions,
      accounts: accounts,
      accountSummaries: sortedAccountSummaries,
      otherCurrencies: otherCurrencies,
      mainCurrencyIncome: mainIncome,
      mainCurrencyExpense: mainExpense,
      mainCurrencyNet: mainNet,
      hasMainCurrencyMovements: hasMainMovements,
      primaryCurrency: primaryCurrency,
      hasPrimaryCurrencyAccounts: hasPrimaryCurrencyAccounts,
    );
  }
}

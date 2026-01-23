import 'package:flutter/material.dart';
import "package:ownfinances/features/transactions/domain/entities/transaction_filters.dart";
import 'package:ownfinances/core/infrastructure/api/api_exception.dart';
import 'package:ownfinances/features/accounts/domain/entities/account.dart';
import 'package:ownfinances/features/accounts/data/repositories/account_repository.dart';
import 'package:ownfinances/features/dashboard/application/state/dashboard_state.dart';
import 'package:ownfinances/features/transactions/domain/entities/transaction.dart';
import 'package:ownfinances/features/transactions/data/repositories/transaction_repository.dart';

import 'package:ownfinances/features/reports/data/repositories/reports_repository.dart';

import 'package:ownfinances/features/settings/application/controllers/settings_controller.dart';

import 'package:ownfinances/features/debts/domain/entities/debt.dart';
import 'package:ownfinances/features/debts/data/repositories/debt_repository.dart';

class DashboardController extends ChangeNotifier {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;
  final ReportsRepository reportsRepository;
  final DebtRepository debtRepository;
  final SettingsController settingsController;

  DashboardState _state = DashboardState.initial();
  bool _isDisposed = false;

  DashboardController(
    this.transactionRepository,
    this.accountRepository,
    this.reportsRepository,
    this.debtRepository,
    this.settingsController,
  ) {
    settingsController.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _isDisposed = true;
    settingsController.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    load();
  }

  DashboardState get state => _state;

  Future<void> load() async {
    if (_isDisposed) return;
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      // 1. Fetch Accounts to know currencies
      final accountsResult = await accountRepository.list(
        isActive: null,
      ); // Fetch all to handle ref to closed accounts
      final accounts = accountsResult.results;

      // 2. Fetch Transactions for the month (pagination loop or large limit)
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

      // 3. Fetch Balances (Total History up to now)
      final balancesReport = await reportsRepository.balances(
        period: "custom",
        date: endOfMonth,
      );

      final balancesMap = {
        for (final b in balancesReport.balances) b.accountId: b.balance,
      };

      // 4. Fetch Active Debts to link with Accounts
      final debtsList = await debtRepository.list();
      final debtsMap = <String, Debt>{};
      for (final debt in debtsList) {
        if (debt.linkedAccountId != null) {
          debtsMap[debt.linkedAccountId!] = debt;
        }
      }

      // 5. Aggregate Data
      _calculateAggregates(accounts, transactions, balancesMap, debtsList);
    } catch (e) {
      if (_isDisposed) return;
      _state = _state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : "Erro ao carregar dashboard",
      );
    }
    if (!_isDisposed) notifyListeners();
  }

  Future<void> setMonth(DateTime date) async {
    if (date.year == _state.date.year && date.month == _state.date.month)
      return;
    if (_isDisposed) return;
    _state = _state.copyWith(date: date);
    notifyListeners();
    await load();
  }

  void _calculateAggregates(
    List<Account> accounts,
    List<Transaction> transactions,
    Map<String, double> balancesMap,
    List<Debt> allDebts,
  ) {
    // --- Rule 2: Month Summary (Dynamic Primary Currency) ---
    final primaryCurrency = settingsController.primaryCurrency;

    // Separate Linkable Debts Map for Accounts
    final debtsMap = <String, Debt>{};
    for (final debt in allDebts) {
      if (debt.linkedAccountId != null) {
        debtsMap[debt.linkedAccountId!] = debt;
      }
    }

    // --- Prepare Account Summaries ---
    final accountSummariesMap = <String, DashboardAccountSummary>{};

    for (final account in accounts) {
      accountSummariesMap[account.id] = DashboardAccountSummary(
        account: account,
        income: 0,
        expense: 0,
        balance: 0, // Month Net Flow
        totalBalance: balancesMap[account.id], // Real Total Balance
        linkedDebt: debtsMap[account.id], // Metadata from Debt Module
        hasMovements: false,
      );
    }

    // Initialize totalPaidDebts
    double totalPaidDebts = 0.0;

    // Process Transactions
    for (final tx in transactions) {
      final absAmount = tx.amount.abs();

      // Check for Debt Payment
      if (tx.type == 'transfer' && tx.toAccountId != null) {
        try {
          final toAccount = accounts.firstWhere((a) => a.id == tx.toAccountId);
          if (toAccount.type == 'credit_card' || toAccount.type == 'loan') {
            // Payment to debt
            final paidAmount = tx.destinationAmount ?? absAmount;
            totalPaidDebts += paidAmount;
          }
        } catch (_) {}
      }

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
            totalBalance: current.totalBalance,
            linkedDebt: current.linkedDebt,
            hasMovements: true,
          );
        }
      }

      if (tx.type == 'income' ||
          (tx.type == 'transfer' && tx.toAccountId != null)) {
        final accId = tx.toAccountId!;
        if (accountSummariesMap.containsKey(accId)) {
          final current = accountSummariesMap[accId]!;
          final inflowAmount =
              (tx.type == 'transfer' && tx.destinationAmount != null)
              ? tx.destinationAmount!
              : absAmount;

          accountSummariesMap[accId] = DashboardAccountSummary(
            account: current.account,
            income: current.income + inflowAmount,
            expense: current.expense,
            balance: current.balance + inflowAmount,
            totalBalance: current.totalBalance,
            linkedDebt: current.linkedDebt,
            hasMovements: true,
          );
        }
      }
    }

    // --- Filter & Sort Main Accounts ---
    // Rules:
    // 1. Exclude Debts/Credit Cards (They go to Debt Section)
    // 2. Exclude Deactivated
    // 3. Priority: Has Movements > Everyday Type > Volume > Name
    // Everyday Type Priority: Bank > Cash > Wallet > Broker, Investment

    final allSummaries = accountSummariesMap.values.toList();
    final nonDebtSummaries = allSummaries.where((s) {
      final isDebt =
          s.account.type == 'credit_card' || s.account.type == 'loan';
      return !isDebt;
    }).toList();

    // Split Active vs Inactive
    final activeSummaries = nonDebtSummaries
        .where((s) => s.account.isActive)
        .toList();
    final inactiveSummaries = nonDebtSummaries
        .where((s) => !s.account.isActive)
        .toList();

    // Priority Helper
    int getTypePriority(String type) {
      final t = type.toLowerCase();
      if (t == 'bank' || t == 'checking') return 1;
      if (t == 'cash') return 2;
      if (t == 'wallet' || t == 'pix') return 3;
      if (t == 'broker' || t == 'investment') return 4;
      return 99;
    }

    // Sort Active for Main Candidates
    activeSummaries.sort((a, b) {
      // 1. Has Movements (Desc)
      if (a.hasMovements && !b.hasMovements) return -1;
      if (!a.hasMovements && b.hasMovements) return 1;

      // 2. Everyday Type (Asc Priority)
      final pA = getTypePriority(a.account.type);
      final pB = getTypePriority(b.account.type);
      if (pA != pB) return pA.compareTo(pB);

      // 3. Volume (Income + Expense) (Desc)
      final valA = a.income + a.expense;
      final valB = b.income + b.expense;
      if (valA != valB) return valB.compareTo(valA);

      // 4. Name (A-Z) (Asc)
      return a.account.name.compareTo(b.account.name);
    });

    List<DashboardAccountSummary> mainAccounts;
    List<DashboardAccountSummary> otherAccounts;

    // Exception Rule: If <= 2 active accounts, show all in Main.
    if (activeSummaries.length <= 2) {
      mainAccounts = activeSummaries;
      otherAccounts = inactiveSummaries;
    } else {
      // Normal Rule
      mainAccounts = activeSummaries.take(5).toList();
      otherAccounts = [...activeSummaries.skip(5), ...inactiveSummaries]
        ..sort((a, b) => a.account.name.compareTo(b.account.name));
    }

    // --- Debts Logic ---
    final activeDebts = allDebts.where((d) => d.isActive).toList();

    // Check Priority (Due within 7 days)
    bool hasPriorityDebt = false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final debt in activeDebts) {
      if (debt.dueDay != null) {
        // Calculate next due date
        // If dueDay >= today.day, it's this month. Else next month.
        DateTime nextDueDate;
        if (debt.dueDay! >= today.day) {
          nextDueDate = DateTime(today.year, today.month, debt.dueDay!);
        } else {
          nextDueDate = DateTime(today.year, today.month + 1, debt.dueDay!);
        }

        final diff = nextDueDate.difference(today).inDays;
        if (diff >= 0 && diff <= 7) {
          hasPriorityDebt = true;
          break;
        }
      }
    }

    _state = _state.copyWith(
      isLoading: false,
      transactions: transactions,
      accounts: accounts,
      mainAccounts: mainAccounts,
      otherAccounts: otherAccounts,
      activeDebts: activeDebts,
      hasPriorityDebt: hasPriorityDebt,
      totalPaidDebts: totalPaidDebts,
      primaryCurrency: primaryCurrency,
    );
  }
}

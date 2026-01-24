import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ownfinances/core/presentation/components/month_picker_dialog.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/core/utils/formatters.dart';
import 'package:ownfinances/core/utils/ui_helpers.dart';
import 'package:ownfinances/features/month_summary/application/controllers/month_summary_controller.dart';
import 'package:ownfinances/features/month_summary/application/state/month_summary_state.dart';
import 'package:ownfinances/features/transactions/application/controllers/transactions_controller.dart';
import 'package:ownfinances/features/transactions/domain/entities/transaction_filters.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/money_text.dart';
import 'package:ownfinances/l10n/app_localizations.dart';

class MonthSummaryScreen extends StatefulWidget {
  const MonthSummaryScreen({super.key});

  @override
  State<MonthSummaryScreen> createState() => _MonthSummaryScreenState();
}

class _MonthSummaryScreenState extends State<MonthSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MonthSummaryController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MonthSummaryController>();
    final state = controller.state;
    final primaryCurrency = state.primaryCurrency;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.monthSummaryTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              //Tab(text: "Moeda principal ($primaryCurrency)"),
              Tab(
                text: AppLocalizations.of(context)!.monthSummaryTabCategories,
              ),
              Tab(text: AppLocalizations.of(context)!.monthSummaryTabAccounts),
              Tab(
                text: AppLocalizations.of(
                  context,
                )!.monthSummaryTabOtherCurrencies,
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _pickMonth(context, state.date),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(formatMonth(state.date)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Header Helper
            Container(
              width: double.infinity,
              color: AppColors.surface2,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Text(
                AppLocalizations.of(context)!.monthSummaryHeaderHelper,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _PrimaryCurrencyTab(state: state),
                        _ByAccountTab(state: state),
                        _OtherCurrenciesTab(state: state),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context, DateTime current) async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => MonthPickerDialog(
        initialDate: current,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      ),
    );

    if (selected != null && context.mounted) {
      context.read<MonthSummaryController>().setDate(selected);
    }
  }
}

class _PrimaryCurrencyTab extends StatelessWidget {
  final MonthSummaryState state;

  const _PrimaryCurrencyTab({required this.state});

  @override
  Widget build(BuildContext context) {
    // Empty state for BRL
    if (!state.hasPrimaryMovements && state.categoryExpenses.isEmpty) {
      // Check if there are movements in other currencies to show specific CTA
      final hasOther = state.currencyFlows.isNotEmpty;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.savings_outlined,
              size: 64,
              color: AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(
                context,
              )!.monthSummaryEmptyPrimary(state.primaryCurrency),
              style: const TextStyle(color: AppColors.muted),
            ),
            if (hasOther) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  DefaultTabController.of(
                    context,
                  ).animateTo(2); // Go to "Outras moedas"
                },
                child: Text(
                  AppLocalizations.of(context)!.monthSummarySeeOtherCurrencies,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: state.categoryExpenses.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = state.categoryExpenses[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      parseColor(item.categoryColor) ?? AppColors.surface2,
                  child: getIconFor(item.categoryIcon) != null
                      ? Icon(
                          getIconFor(item.categoryIcon),
                          color: parseColor(item.categoryColor) == null
                              ? AppColors.textPrimary
                              : Colors.white,
                          size: 20,
                        )
                      : Text(
                          item.categoryName.isNotEmpty
                              ? item.categoryName[0]
                              : "?",
                          style: TextStyle(
                            color: parseColor(item.categoryColor) == null
                                ? AppColors.textPrimary
                                : Colors.white,
                          ),
                        ),
                ), // Icon rendered correctly
                title: Text(item.categoryName),
                subtitle: item.otherCurrencies.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Wrap(
                          spacing: 8,
                          children: item.otherCurrencies
                              .map(
                                (c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface2,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.borderSoft,
                                    ),
                                  ),
                                  child: Text(
                                    "${c.currency} ${formatMoney(c.expense, withSymbol: false)}", // Compact
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      )
                    : null,
                trailing: MoneyText(
                  value: item.amount,
                  symbol: state.primaryCurrency,
                  variant: MoneyTextVariant.m,
                ),
                onTap: () {
                  // Filter Transactions
                  final start = DateTime(state.date.year, state.date.month, 1);
                  final end = DateTime(
                    state.date.year,
                    state.date.month + 1,
                    0,
                    23,
                    59,
                    59,
                  );

                  context.read<TransactionsController>().setFilters(
                    TransactionFilters(
                      dateFrom: start,
                      dateTo: end,
                      categoryId: item.categoryId,
                    ),
                  );
                  context.push("/month-summary/details");
                },
              );
            },
          ),
        ),
        // Sticky Footer
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.surface1,
            border: Border(top: BorderSide(color: AppColors.borderSoft)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.monthSummaryTotalSpent(state.primaryCurrency),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  MoneyText(
                    value: state.totalPrimaryExpense,
                    symbol: state.primaryCurrency,
                    variant: MoneyTextVariant.l,
                    color: AppColors.danger,
                  ),
                ],
              ),
              if (state.otherCurrencyTotals.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.monthSummaryOtherCurrencies,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: state.otherCurrencyTotals
                          .map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                "${t.currency} ${formatMoney(t.expense)}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ByAccountTab extends StatelessWidget {
  final MonthSummaryState state;
  const _ByAccountTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.accountFlows.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.monthSummaryNoAccounts,
          style: const TextStyle(color: AppColors.muted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.accountFlows.length,
      itemBuilder: (context, index) {
        final flow = state.accountFlows[index];
        final account = flow.account;

        final isDebt = account.type == 'credit_card' || account.type == 'debt';

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        account.currency,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (!isDebt)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.monthSummaryIncome,
                        style: const TextStyle(color: AppColors.success),
                      ),
                      MoneyText(
                        value: flow.income,
                        symbol: account.currency,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                if (isDebt)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.monthSummaryPayments, // "Entradas" in debt account = Payments made to it
                        style: const TextStyle(color: AppColors.success),
                      ),
                      MoneyText(
                        value: flow.income,
                        symbol: account.currency,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDebt
                          ? AppLocalizations.of(context)!.monthSummaryPurchases
                          : AppLocalizations.of(context)!.monthSummaryExpenses,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    MoneyText(
                      value: flow.expense,
                      symbol: account.currency,
                      color: AppColors.danger,
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDebt
                          ? AppLocalizations.of(context)!.monthSummaryNetMonth
                          : AppLocalizations.of(
                              context,
                            )!.monthSummaryBalanceMonth,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    MoneyText(
                      value: flow.net,
                      symbol: account.currency,
                      variant: MoneyTextVariant.m,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    child: Text(
                      isDebt
                          ? AppLocalizations.of(
                              context,
                            )!.monthSummaryViewInvoice
                          : AppLocalizations.of(
                              context,
                            )!.monthSummaryViewTransactions,
                    ),
                    onPressed: () {
                      final start = DateTime(
                        state.date.year,
                        state.date.month,
                        1,
                      );
                      final end = DateTime(
                        state.date.year,
                        state.date.month + 1,
                        0,
                        23,
                        59,
                        59,
                      );

                      context.read<TransactionsController>().setFilters(
                        TransactionFilters(
                          dateFrom: start,
                          dateTo: end,
                          accountId: account.id,
                        ),
                      );
                      context.push("/month-summary/details");
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OtherCurrenciesTab extends StatelessWidget {
  final MonthSummaryState state;
  const _OtherCurrenciesTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.currencyFlows.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.monthSummaryNoOtherCurrencies,
          style: const TextStyle(color: AppColors.muted),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.surface2.withOpacity(0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.monthSummaryOtherCurrencies,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(
                  context,
                )!.monthSummaryOtherCurrenciesSubtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: state.currencyFlows.length,
            padding: const EdgeInsets.all(AppSpacing.md),
            separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final flow = state.currencyFlows[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flow.currency,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.monthSummaryIncome,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              MoneyText(
                                value: flow.income,
                                symbol: flow.currency,
                                color: AppColors.success,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.monthSummaryExpenses,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              MoneyText(
                                value: flow.expense,
                                symbol: flow.currency,
                                color: AppColors.danger,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.monthSummaryNet),
                          MoneyText(
                            value: flow.net,
                            symbol: flow.currency,
                            variant: MoneyTextVariant.l,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

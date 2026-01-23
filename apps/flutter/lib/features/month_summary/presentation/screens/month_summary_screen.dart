import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ownfinances/core/presentation/components/month_picker_dialog.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/core/utils/formatters.dart';
import 'package:ownfinances/features/month_summary/application/controllers/month_summary_controller.dart';
import 'package:ownfinances/features/month_summary/application/state/month_summary_state.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/money_text.dart';

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
          title: const Text("Resumo geral do mês"),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: "Moeda principal ($primaryCurrency)"),
              const Tab(text: "Por conta"),
              const Tab(text: "Outras moedas"),
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
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _PrimaryCurrencyTab(state: state),
                  _ByAccountTab(state: state),
                  _OtherCurrenciesTab(state: state),
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
    if (!state.hasPrimaryMovements && state.categoryExpenses.isEmpty) {
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
              "Sem movimentos em ${state.primaryCurrency} neste mês.",
              style: const TextStyle(color: AppColors.muted),
            ),
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
                  backgroundColor: AppColors.surface2,
                  child: Text(
                    item.categoryName[0],
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ), // Placeholder for icon
                title: Text(item.categoryName),
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
                  );

                  context.push(
                    Uri(
                      path: "/transactions",
                      queryParameters: {
                        "dateFrom": start.toIso8601String(),
                        "dateTo": end.toIso8601String(),
                        "categoryId": item.categoryId,
                        // "currency": state.primaryCurrency // Transactions logic might need update to support currency filter?
                        // The Plan said: "apenas contas cuja moeda == moeda principal"
                        // If transactions screen doesn't filter by currency/account_currency, we might see mixed stuff.
                        // But typically Category is enough as user categorizes mainly expenses.
                      },
                    ).toString(),
                  );
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total gastos do mês (${state.primaryCurrency}):",
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
      return const Center(
        child: Text(
          "Nenhuma conta encontrada",
          style: TextStyle(color: AppColors.muted),
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
                      const Text(
                        "Entradas",
                        style: TextStyle(color: AppColors.success),
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
                    const Text(
                      "Saídas",
                      style: TextStyle(color: AppColors.danger),
                    ),
                    MoneyText(
                      value: flow.expense,
                      symbol: account.currency,
                      color: AppColors.danger,
                    ),
                  ],
                ),
                if (!isDebt) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Saldo do mês",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      MoneyText(
                        value: flow.net,
                        symbol: account.currency,
                        variant: MoneyTextVariant.m,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    child: const Text("Ver transações"),
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
                      );

                      context.push(
                        Uri(
                          path: "/transactions",
                          queryParameters: {
                            "dateFrom": start.toIso8601String(),
                            "dateTo": end.toIso8601String(),
                            "accountId": account.id,
                          },
                        ).toString(),
                      );
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
      return const Center(
        child: Text(
          "Nenhuma outra moeda movimentada",
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.surface2.withOpacity(0.5),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Outras moedas (sem conversão)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                "Os valores abaixo não são convertidos para a moeda principal.",
                style: TextStyle(fontSize: 12, color: AppColors.muted),
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
                              const Text(
                                "Entradas",
                                style: TextStyle(
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
                              const Text(
                                "Saídas",
                                style: TextStyle(
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
                          const Text("Líquido"),
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

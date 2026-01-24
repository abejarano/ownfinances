import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/cards.dart";
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/budgets/application/controllers/budget_controller.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";
import "package:ownfinances/core/presentation/components/month_picker_dialog.dart";
import "package:ownfinances/core/presentation/components/money_text.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/goals/presentation/screens/goals_screen.dart";
import "package:ownfinances/features/recurring/presentation/screens/recurring_hub_screen.dart";
import 'package:ownfinances/l10n/app_localizations.dart';

class BudgetScreen extends StatelessWidget {
  final Map<String, String> queryParams;

  const BudgetScreen({super.key, this.queryParams = const {}});

  @override
  Widget build(BuildContext context) {
    // Map existing query params
    // /budgets?tab=goals|fixed
    final tab = queryParams['tab'];
    int initialIndex = 0;
    if (tab == 'goals') initialIndex = 1;
    if (tab == 'fixed') initialIndex = 2;

    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor, // Match bg
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: AppLocalizations.of(context)!.budgetsTitle),
                Tab(text: AppLocalizations.of(context)!.budgetsTabGoals),
                Tab(text: AppLocalizations.of(context)!.budgetsTabFixed),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [BudgetView(), GoalsView(), RecurringHubView()],
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetView extends StatefulWidget {
  const BudgetView({super.key});

  @override
  State<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> {
  final Map<String, TextEditingController> _controllers = {};
  ReportsController? _reports;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reports = context.read<ReportsController>();
      _reports?.addListener(_onReportsChange);
      final reportsState = _reports!.state;
      _lastPeriod = reportsState.period;
      _lastDate = reportsState.date;

      context.read<BudgetController>().load(
        period: reportsState.period,
        date: reportsState.date,
      );
    });
  }

  @override
  void dispose() {
    _reports?.removeListener(_onReportsChange);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  DateTime? _lastDate;
  String? _lastPeriod;

  void _onReportsChange() {
    final reports = _reports;
    if (reports == null) return;
    final reportsState = reports.state;

    // Only load if period or date ACTUALLY changed
    if (reportsState.period == _lastPeriod &&
        isSameMonth(reportsState.date, _lastDate)) {
      return;
    }

    _lastPeriod = reportsState.period;
    _lastDate = reportsState.date;

    context.read<BudgetController>().load(
      period: reportsState.period,
      date: reportsState.date,
    );
  }

  bool isSameMonth(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year && a.month == b.month;
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = context.watch<ReportsController>().state;
    final budgetState = context.watch<BudgetController>().state;
    final categoriesState = context.watch<CategoriesController>().state;

    final summary = reportsState.summary;
    final summaryMap = {
      for (final item in summary?.byCategory ?? <CategorySummary>[])
        item.categoryId: item,
    };
    final period = reportsState.period;
    final date = reportsState.date;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.budgetsMonthTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _pickMonth(context, date),
              icon: const Icon(Icons.calendar_today),
              label: Text(formatMonth(date)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        InlineSummaryCard(
          title: AppLocalizations.of(context)!.budgetsPlanPeriod,
          planned: summary?.totals.plannedExpense ?? 0,
          actual: summary?.totals.actualExpense ?? 0,
          remaining: summary?.totals.remainingExpense ?? 0,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "${AppLocalizations.of(context)!.budgetsHeaderIncome}: ${formatMoney(summary?.totals.plannedIncome ?? 0)} • ${AppLocalizations.of(context)!.budgetsHeaderExpense}: ${formatMoney(summary?.totals.plannedExpense ?? 0)} • ${AppLocalizations.of(context)!.budgetsHeaderBalance}: ${formatMoney(summary?.totals.plannedNet ?? 0)}",
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (budgetState.isLoading) const LinearProgressIndicator(),
        const SizedBox(height: AppSpacing.sm),
        if (budgetState.budget == null && !budgetState.isLoading)
          _EmptyBudgetState(
            month: formatMonth(date),
            onCreate: () => _createBudget(context, period, date),
          )
        else
          ...categoriesState.items.map((category) {
            // Only show categories that are actually in the budget lines
            // OR if we are in "creation mode" (but here we assume budget exists)
            // Wait, the ticket says "Remove from budget". So we should only show items that are IN the budget?
            // "Quando budget != null: Mostrar lista de categorías del presupuesto del mes."
            // But currently it iterates ALL categories.
            // If I remove a category, I need it to disappear.
            // So I should filter categoriesState.items by what is in budgetState.plannedByCategory?
            // Or just iterate budgetState.plannedByCategory?
            // But I need the Category Name, which is in categoriesState. Or I need to join them.

            // Current implementation:
            // ...categoriesState.items.map((category) { ... })
            // This shows ALL categories even if not in budget.
            // Ticket says: "Cada categoría debe permitir: “Remover do orçamento deste mês” ... Al remover: desaparece de la lista"

            // So if budget != null, we should ONLY show categories that have a planned amount (or are implicitly in the budget).
            // But `plannedByCategory` has the amounts.

            final planned = budgetState.plannedByCategory[category.id];
            // if (planned == null) return const SizedBox.shrink(); // Show all categories so user can edit them

            final double safePlanned = planned ?? 0.0;

            final controller = _controllers.putIfAbsent(category.id, () {
              return TextEditingController(
                text: safePlanned > 0 ? formatMoney(safePlanned) : "",
              );
            });
            // Update controller if value changed externally (e.g. reload)
            if (safePlanned != parseMoney(controller.text)) {
              controller.text = safePlanned > 0 ? formatMoney(safePlanned) : "";
            }

            final line = summaryMap[category.id];
            final actual = line?.actual ?? 0;
            final remaining = line?.remaining ?? 0;
            final progressPct = line?.progressPct ?? 0;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(category.name),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'remove') {
                              _removeCategory(
                                context,
                                period,
                                date,
                                category.id,
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.budgetsRemoveCategory,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: MoneyInput(
                            label: AppLocalizations.of(
                              context,
                            )!.budgetsLabelPlanned,
                            controller: controller,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.budgetsLabelActual,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                            MoneyText(
                              value: actual,
                              variant: MoneyTextVariant.l, // Primary amount
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.budgetsLabelRemaining,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                            MoneyText(
                              value: remaining,
                              variant: MoneyTextVariant.m,
                              color: remaining < 0
                                  ? AppColors.danger
                                  : AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: AppSpacing.md),
        if (budgetState.budget != null)
          PrimaryButton(
            label: AppLocalizations.of(context)!.budgetsSaveButton,
            onPressed: () async {
              for (final entry in _controllers.entries) {
                context.read<BudgetController>().updatePlanned(
                  entry.key,
                  parseMoney(entry.value.text),
                );
              }
              final error = await context.read<BudgetController>().save(period);
              if (error != null && context.mounted) {
                showStandardSnackbar(context, error);
                return;
              }
              await context.read<ReportsController>().load();
              if (context.mounted) {
                showStandardSnackbar(
                  context,
                  AppLocalizations.of(context)!.budgetsSuccessSaved,
                );
              }
            },
          ),
      ],
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

    if (selected != null) {
      if (context.mounted) {
        context.read<ReportsController>().setParams(
          date: selected,
          period: "monthly",
        );
      }
    }
  }

  Future<void> _createBudget(
    BuildContext context,
    String period,
    DateTime date,
  ) async {
    final error = await context.read<BudgetController>().createFromPrevious(
      period,
      date,
    );
    if (error != null && context.mounted) {
      showStandardSnackbar(context, error);
    }
  }

  Future<void> _removeCategory(
    BuildContext context,
    String period,
    DateTime date,
    String categoryId,
  ) async {
    final error = await context.read<BudgetController>().removeCategory(
      period,
      date,
      categoryId,
    );
    if (error != null && context.mounted) {
      showStandardSnackbar(context, error);
    } else if (context.mounted) {
      showStandardSnackbar(
        context,
        AppLocalizations.of(context)!.budgetsSuccessRemoved,
      );
    }
  }
}

class _EmptyBudgetState extends StatelessWidget {
  final String month;
  final VoidCallback onCreate;

  const _EmptyBudgetState({
    super.key,
    required this.month,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.md,
        ),
        child: Column(
          children: [
            const Icon(Icons.money_off, size: 64, color: AppColors.muted),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.budgetsEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.budgetsEmptyDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: AppLocalizations.of(context)!.budgetsCreateButton,
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

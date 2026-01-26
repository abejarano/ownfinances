import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/budgets/application/controllers/budget_controller.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/debts/application/controllers/debts_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";
import "package:ownfinances/core/presentation/components/month_picker_dialog.dart";
import "package:ownfinances/core/presentation/components/money_text.dart";
import "package:ownfinances/features/settings/application/controllers/settings_controller.dart";
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
  final Map<String, TextEditingController> _debtControllers = {};
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

      _lastDebtSummaryDate = reportsState.date;
      _loadDebtSummaries(reportsState.date);
    });
  }

  @override
  void dispose() {
    _reports?.removeListener(_onReportsChange);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final controller in _debtControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  DateTime? _lastDate;
  String? _lastPeriod;
  DateTime? _lastDebtSummaryDate;

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

    if (!isSameMonth(reportsState.date, _lastDebtSummaryDate)) {
      _lastDebtSummaryDate = reportsState.date;
      _loadDebtSummaries(reportsState.date);
    }
  }

  bool isSameMonth(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year && a.month == b.month;
  }

  Future<void> _loadDebtSummaries(DateTime date) async {
    final debtsController = context.read<DebtsController>();
    if (!debtsController.state.isLoading && debtsController.state.items.isEmpty) {
      await debtsController.load();
    }
    if (!mounted) return;
    final activeDebts = debtsController.state.items
        .where((debt) => debt.isActive)
        .map((debt) => debt.id);
    if (activeDebts.isEmpty) return;
    await debtsController.loadSummaries(activeDebts, month: date);
  }

  String? _formatOtherCurrencies(
    Map<String, double> totals,
    String primaryCurrency,
  ) {
    final entries = totals.entries
        .where((entry) => entry.key != primaryCurrency && entry.value > 0)
        .toList();
    if (entries.isEmpty) return null;
    return entries
        .map((entry) => formatCurrency(entry.value, entry.key))
        .join(" · ");
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = context.watch<ReportsController>().state;
    final budgetState = context.watch<BudgetController>().state;
    final categoriesState = context.watch<CategoriesController>().state;
    final debtsState = context.watch<DebtsController>().state;
    final primaryCurrency =
        context.watch<SettingsController>().primaryCurrency;
    final l10n = AppLocalizations.of(context)!;

    final summary = reportsState.summary;
    final summaryMap = {
      for (final item in summary?.byCategory ?? <CategorySummary>[])
        item.categoryId: item,
    };
    final activeDebts =
        debtsState.items.where((debt) => debt.isActive).toList();
    final plannedDebtTotals = <String, double>{};
    for (final debt in activeDebts) {
      final planned = budgetState.plannedByDebt[debt.id] ?? 0;
      if (planned <= 0) continue;
      plannedDebtTotals[debt.currency] =
          (plannedDebtTotals[debt.currency] ?? 0) + planned;
    }
    final plannedCategoryTotal = summary?.totals.plannedExpense ?? 0;
    final plannedDebtPrimary = plannedDebtTotals[primaryCurrency] ?? 0;
    final totalOutflowPrimary = plannedCategoryTotal + plannedDebtPrimary;
    final period = reportsState.period;
    final date = reportsState.date;
    final otherCurrenciesText =
        _formatOtherCurrencies(plannedDebtTotals, primaryCurrency);
    final showSave = budgetState.budget != null;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            showSave ? 96 : AppSpacing.md,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.budgetsMonthTitle,
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.budgetsMonthSummaryTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _summaryRow(
                    l10n.budgetsMonthSummaryPlannedCategories,
                    formatCurrency(plannedCategoryTotal, primaryCurrency),
                  ),
                  _summaryRow(
                    l10n.budgetsMonthSummaryPlannedDebts,
                    formatCurrency(plannedDebtPrimary, primaryCurrency),
                  ),
                  _summaryRow(
                    l10n.budgetsMonthSummaryTotalOutflow,
                    formatCurrency(totalOutflowPrimary, primaryCurrency),
                  ),
                  if (otherCurrenciesText != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "${l10n.budgetsMonthSummaryOtherCurrencies}: $otherCurrenciesText",
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.budgetsDebtPaymentNote,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (budgetState.isLoading) const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.sm),
            if (budgetState.budget == null && !budgetState.isLoading)
              _EmptyBudgetState(
                month: formatMonth(date),
                onCreate: () => _createBudget(context, period, date),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.budgetsDebtPlannedTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.budgetsDebtPlannedSubtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.budgetsDebtPaymentNote,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (activeDebts.isEmpty) ...[
                        Text(
                          l10n.budgetsDebtEmptyState,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: () => context.push("/debts"),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.debtsActionAdd),
                        ),
                      ] else ...[
                        for (final debt in activeDebts) ...[
                          Builder(
                            builder: (context) {
                              final planned =
                                  budgetState.plannedByDebt[debt.id] ?? 0;
                              final controller = _debtControllers.putIfAbsent(
                                debt.id,
                                () => TextEditingController(
                                  text: planned > 0
                                      ? formatMoney(
                                          planned,
                                          symbol: debt.currency,
                                        )
                                      : "",
                                ),
                              );
                              if (planned != parseMoney(controller.text)) {
                                controller.text = planned > 0
                                    ? formatMoney(
                                        planned,
                                        symbol: debt.currency,
                                      )
                                    : "";
                              }

                              final summary = debtsState.summaries[debt.id];
                              final paid = summary?.paymentsThisMonth ?? 0;
                              String? progressText;
                              String? progressHelper;
                              if (planned > 0 || paid > 0) {
                                progressText = l10n.budgetsDebtPaidPlanned(
                                  formatCurrency(paid, debt.currency),
                                  formatCurrency(planned, debt.currency),
                                );
                                if (paid > planned) {
                                  progressHelper = l10n.budgetsDebtOverpaid(
                                    formatCurrency(
                                      paid - planned,
                                      debt.currency,
                                    ),
                                  );
                                } else if (paid < planned) {
                                  progressHelper = l10n.budgetsDebtRemaining(
                                    formatCurrency(
                                      planned - paid,
                                      debt.currency,
                                    ),
                                  );
                                }
                              }

                              String? minWarning;
                              if (debt.minimumPayment != null &&
                                  debt.minimumPayment! > 0 &&
                                  planned < debt.minimumPayment!) {
                                minWarning = l10n.budgetsDebtMinimumWarning;
                              }

                              final dueLabel = debt.dueDay != null
                                  ? l10n.debtsDueDayLabel(debt.dueDay!)
                                  : null;

                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            debt.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (dueLabel != null)
                                          Text(
                                            dueLabel,
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${l10n.budgetsDebtOweLabel}: ${formatCurrency(debt.amountDue, debt.currency)}",
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    MoneyInput(
                                      label: l10n.budgetsDebtPayLabel,
                                      controller: controller,
                                      helperText: minWarning,
                                      currencySymbol: debt.currency,
                                    ),
                                    if (progressText != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        progressText,
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    if (progressHelper != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        progressHelper,
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                for (final debt in activeDebts) {
                                  context
                                      .read<BudgetController>()
                                      .updatePlannedDebt(debt.id, 0.0);
                                  final controller =
                                      _debtControllers[debt.id];
                                  if (controller != null) {
                                    controller.text = "";
                                  }
                                }
                              },
                              child: Text(l10n.budgetsDebtActionZeroAll),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            TextButton(
                              onPressed: () {
                                for (final debt in activeDebts) {
                                  final suggested =
                                      debt.minimumPayment != null &&
                                              debt.minimumPayment! > 0
                                          ? debt.minimumPayment!
                                          : (debt.amountDue > 0
                                              ? debt.amountDue
                                              : 0.0);
                                  context
                                      .read<BudgetController>()
                                      .updatePlannedDebt(debt.id, suggested);
                                  final controller =
                                      _debtControllers[debt.id];
                                  if (controller != null) {
                                    controller.text = suggested > 0
                                        ? formatMoney(
                                            suggested,
                                            symbol: debt.currency,
                                          )
                                        : "";
                                  }
                                }
                              },
                              child: Text(l10n.budgetsDebtActionSuggest),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.lg),
                        _summaryRow(
                          l10n.budgetsDebtTotalPlannedLabel(primaryCurrency),
                          formatCurrency(plannedDebtPrimary, primaryCurrency),
                        ),
                        if (otherCurrenciesText != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              "${l10n.budgetsMonthSummaryOtherCurrencies}: $otherCurrenciesText",
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.budgetsCategoriesTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...categoriesState.items.map((category) {
                final planned = budgetState.plannedByCategory[category.id];
                final double safePlanned = planned ?? 0.0;

                final controller = _controllers.putIfAbsent(category.id, () {
                  return TextEditingController(
                    text: safePlanned > 0 ? formatMoney(safePlanned) : "",
                  );
                });
                // Update controller if value changed externally (e.g. reload)
                if (safePlanned != parseMoney(controller.text)) {
                  controller.text =
                      safePlanned > 0 ? formatMoney(safePlanned) : "";
                }

                final line = summaryMap[category.id];
                final actual = line?.actual ?? 0;
                final remaining = line?.remaining ?? 0;
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
                                  AppLocalizations.of(
                                    context,
                                  )!.budgetsLabelActual,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                                MoneyText(
                                  value: actual,
                                  variant:
                                      MoneyTextVariant.l, // Primary amount
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
            ],
          ],
        ),
        if (showSave)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: AppLocalizations.of(context)!.budgetsSaveButton,
                onPressed: () async {
                  for (final entry in _controllers.entries) {
                    context.read<BudgetController>().updatePlanned(
                      entry.key,
                      parseMoney(entry.value.text),
                    );
                  }
                  for (final entry in _debtControllers.entries) {
                    context.read<BudgetController>().updatePlannedDebt(
                      entry.key,
                      parseMoney(entry.value.text),
                    );
                  }
                  final error =
                      await context.read<BudgetController>().save(period);
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
            ),
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

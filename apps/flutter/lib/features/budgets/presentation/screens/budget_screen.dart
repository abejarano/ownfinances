import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/budgets/application/controllers/budget_controller.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_category_card.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_debt_planned_card.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_empty_state.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_month_summary_card.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/debts/application/controllers/debts_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";
import "package:ownfinances/core/presentation/components/month_picker_dialog.dart";
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
    final budgetCategoryIds = budgetState.budget?.lines
            .map((line) => line.categoryId)
            .toSet() ??
        <String>{};
    final budgetCategories = categoriesState.items
        .where((category) => budgetCategoryIds.contains(category.id))
        .toList();

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
            BudgetMonthSummaryCard(
              plannedCategoryTotal: plannedCategoryTotal,
              plannedDebtPrimary: plannedDebtPrimary,
              totalOutflowPrimary: totalOutflowPrimary,
              primaryCurrency: primaryCurrency,
              otherCurrenciesText: otherCurrenciesText,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (budgetState.isLoading) const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.sm),
            if (budgetState.budget == null && !budgetState.isLoading)
              BudgetEmptyState(
                month: formatMonth(date),
                onCreate: () => _createBudget(context, period, date),
              )
            else ...[
              BudgetDebtPlannedCard(
                debts: activeDebts,
                plannedByDebt: budgetState.plannedByDebt,
                summaries: debtsState.summaries,
                controllers: _debtControllers,
                plannedDebtPrimary: plannedDebtPrimary,
                primaryCurrency: primaryCurrency,
                otherCurrenciesText: otherCurrenciesText,
                onAddDebt: () => context.push("/debts"),
                onUpdatePlanned: (debtId, amount) {
                  context
                      .read<BudgetController>()
                      .updatePlannedDebt(debtId, amount);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.budgetsCategoriesTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...budgetCategories.map((category) {
                final planned =
                    budgetState.plannedByCategory[category.id] ?? 0.0;
                final controller = _controllers.putIfAbsent(
                  category.id,
                  () => TextEditingController(),
                );
                final actualByCurrency =
                    summaryMap[category.id]?.actualByCurrency ?? {};
                final actualPrimary =
                    actualByCurrency[primaryCurrency] ?? 0.0;
                final otherCurrencyTotals = Map<String, double>.fromEntries(
                  actualByCurrency.entries.where(
                    (entry) =>
                        entry.key != primaryCurrency && entry.value != 0,
                  ),
                );
                return BudgetCategoryCard(
                  category: category,
                  controller: controller,
                  planned: planned,
                  actual: actualPrimary,
                  otherCurrencyTotals: otherCurrencyTotals,
                  onRemove: () => _removeCategory(
                    context,
                    period,
                    date,
                    category.id,
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

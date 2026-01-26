import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/budgets/application/controllers/budget_controller.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_categories_tab.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_debts_tab.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_segments_control.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_summary_tab.dart";
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
    final plannedDebtPrimary = plannedDebtTotals[primaryCurrency] ?? 0;
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

    final plannedExpenseTotal = budgetState.plannedByCategory.entries
        .where((entry) => summaryMap[entry.key]?.kind == "expense")
        .fold(0.0, (sum, entry) => sum + entry.value);
    final actualExpenseTotalPrimary = budgetState.plannedByCategory.entries
        .where((entry) => summaryMap[entry.key]?.kind == "expense")
        .fold(0.0, (sum, entry) {
      final actualByCurrency =
          summaryMap[entry.key]?.actualByCurrency ?? {};
      return sum + (actualByCurrency[primaryCurrency] ?? 0.0);
    });
    final overspentCount = budgetState.plannedByCategory.entries
        .where((entry) => summaryMap[entry.key]?.kind == "expense")
        .where((entry) {
      final actualByCurrency =
          summaryMap[entry.key]?.actualByCurrency ?? {};
      return (actualByCurrency[primaryCurrency] ?? 0.0) > entry.value;
    }).length;
    final dueDays = activeDebts
        .map((debt) => debt.dueDay)
        .whereType<int>()
        .toList()
      ..sort();
    final nextDueDay = dueDays.isEmpty ? null : dueDays.first;

    Future<void> saveCategories() async {
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
    }

    Future<void> saveDebts() async {
      for (final entry in _debtControllers.entries) {
        context.read<BudgetController>().updatePlannedDebt(
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
    }

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context)!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.budgetsTitle,
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
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: BudgetSegmentsControl(),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: TabBarView(
                  children: [
                    BudgetCategoriesTab(
                      isLoading: budgetState.isLoading,
                      hasBudget: budgetState.budget != null,
                      categories: budgetCategories,
                      controllers: _controllers,
                      summaryMap: summaryMap,
                      plannedByCategory: budgetState.plannedByCategory,
                      primaryCurrency: primaryCurrency,
                      onCreateBudget: () => _createBudget(
                        context,
                        period,
                        date,
                      ),
                      onRemoveCategory: (categoryId) => _removeCategory(
                        context,
                        period,
                        date,
                        categoryId,
                      ),
                      onSave: saveCategories,
                      showSave: showSave,
                    ),
                    BudgetDebtsTab(
                      isLoading: budgetState.isLoading,
                      hasBudget: budgetState.budget != null,
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
                      onCreateBudget: () => _createBudget(
                        context,
                        period,
                        date,
                      ),
                      onSave: saveDebts,
                      showSave: showSave,
                    ),
                    BudgetSummaryTab(
                      plannedExpense: plannedExpenseTotal,
                      actualExpense: actualExpenseTotalPrimary,
                      overspentCount: overspentCount,
                      plannedDebt: plannedDebtPrimary,
                      nextDueDay: nextDueDay,
                      primaryCurrency: primaryCurrency,
                      onViewCategories: () => tabController.animateTo(0),
                      onViewDebts: () => tabController.animateTo(1),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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

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
  final Map<String, TextEditingController> _debtControllers = {};
  ReportsController? _reports;
  TabController? _innerTabController;
  bool _debtsTabRequested = false;

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

      _lastDebtSummaryDate = null;
    });
  }

  @override
  void dispose() {
    _reports?.removeListener(_onReportsChange);
    _innerTabController?.removeListener(_onInnerTabChange);
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

    if (_debtsTabRequested && _innerTabController?.index == 1) {
      _maybeLoadDebtSummaries(reportsState.date);
    }
  }

  bool isSameMonth(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year && a.month == b.month;
  }

  Future<void> _loadDebtSummaries(DateTime date) async {
    final debtsController = context.read<DebtsController>();
    if (!debtsController.state.isLoading &&
        debtsController.state.items.isEmpty) {
      await debtsController.load();
    }
    if (!mounted) return;
    final activeDebts = debtsController.state.items
        .where((debt) => debt.isActive)
        .map((debt) => debt.id);
    if (activeDebts.isEmpty) return;
    await debtsController.loadSummaries(activeDebts, month: date);
  }

  Future<void> _maybeLoadDebtSummaries(DateTime date) async {
    if (isSameMonth(date, _lastDebtSummaryDate)) return;
    _lastDebtSummaryDate = date;
    await _loadDebtSummaries(date);
  }

  void _attachTabController(TabController controller) {
    if (_innerTabController == controller) return;
    _innerTabController?.removeListener(_onInnerTabChange);
    _innerTabController = controller;
    controller.addListener(_onInnerTabChange);
  }

  void _onInnerTabChange() {
    final controller = _innerTabController;
    if (controller == null || controller.indexIsChanging) return;
    if (controller.index == 1 && controller.previousIndex != 1) {
      _debtsTabRequested = true;
      final reportsState = _reports?.state;
      if (reportsState != null) {
        _maybeLoadDebtSummaries(reportsState.date);
      }
    }
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
    final primaryCurrency = context.watch<SettingsController>().primaryCurrency;
    final l10n = AppLocalizations.of(context)!;

    final summary = reportsState.summary;
    final summaryMap = {
      for (final item in summary?.byCategory ?? <CategorySummary>[])
        item.categoryId: item,
    };
    final activeDebts = debtsState.items
        .where((debt) => debt.isActive)
        .toList();
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
    final otherCurrenciesText = _formatOtherCurrencies(
      plannedDebtTotals,
      primaryCurrency,
    );
    final categories = categoriesState.items;
    final categoryKindById = {
      for (final category in categories) category.id: category.kind,
    };
    final plannedExpenseTotal = budgetState.planCategories
        .where((plan) => categoryKindById[plan.categoryId] == "expense")
        .fold(0.0, (sum, plan) => sum + plan.plannedTotal);
    final plannedIncomeTotal = budgetState.planCategories
        .where((plan) => categoryKindById[plan.categoryId] == "income")
        .fold(0.0, (sum, plan) => sum + plan.plannedTotal);
    final estimatedAvailable = otherCurrenciesText == null
        ? plannedIncomeTotal - plannedExpenseTotal - plannedDebtPrimary
        : null;
    final hasDebtEdits = _debtControllers.entries.any((entry) {
      final planned = budgetState.plannedByDebt[entry.key] ?? 0.0;
      return parseMoney(entry.value.text) != planned;
    });
    final showSnapshotPrompt =
        budgetState.budget == null &&
        !budgetState.snapshotDismissed &&
        budgetState.planCategories.isEmpty &&
        budgetState.plannedByDebt.isEmpty &&
        !hasDebtEdits;
    final isOnboarding = budgetState.budget == null;
    final showSave = budgetState.hasChanges || hasDebtEdits;

    Future<String?> saveBudget({required bool showSuccess}) async {
      for (final entry in _debtControllers.entries) {
        context.read<BudgetController>().updatePlannedDebt(
          entry.key,
          parseMoney(entry.value.text),
        );
      }
      final error = await context.read<BudgetController>().save(
        period,
        date: date,
      );
      if (error != null && context.mounted) {
        showStandardSnackbar(context, error);
        return error;
      }
      await context.read<ReportsController>().load();
      if (showSuccess && context.mounted) {
        showStandardSnackbar(
          context,
          AppLocalizations.of(context)!.budgetsSuccessSaved,
        );
      }
      return null;
    }

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context)!;
          _attachTabController(tabController);
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
                      isOnboarding: isOnboarding,
                      showSnapshotPrompt: showSnapshotPrompt,
                      categories: categories,
                      planCategories: budgetState.planCategories,
                      summaryMap: summaryMap,
                      primaryCurrency: primaryCurrency,
                      onApplySnapshot: () async {
                        final ok = await context
                            .read<BudgetController>()
                            .applySnapshot(period: period, date: date);
                        if (!ok && context.mounted) {
                          showStandardSnackbar(
                            context,
                            l10n.budgetsSnapshotNotFound,
                          );
                        }
                      },
                      onStartFresh: () =>
                          context.read<BudgetController>().clearPlan(),
                      onAddEntry: (categoryId, amount, description) async {
                        return context.read<BudgetController>().addEntry(
                          period: period,
                          date: date,
                          categoryId: categoryId,
                          amount: amount,
                          description: description,
                        );
                      },
                      onRemoveEntry: (entryId) =>
                          context.read<BudgetController>().removeEntry(entryId),
                      onRemoveCategory: (categoryId) {
                        context.read<BudgetController>().removeCategoryEntries(
                          categoryId,
                        );
                        if (context.mounted) {
                          showStandardSnackbar(
                            context,
                            AppLocalizations.of(context)!.budgetsSuccessRemoved,
                          );
                        }
                      },
                      onSave: () => saveBudget(showSuccess: true),
                      onSaveEntry: () => saveBudget(showSuccess: false),
                      showSave: showSave,
                    ),
                    BudgetDebtsTab(
                      isLoading: budgetState.isLoading,
                      debts: activeDebts,
                      plannedByDebt: budgetState.plannedByDebt,
                      summaries: debtsState.summaries,
                      controllers: _debtControllers,
                      plannedDebtPrimary: plannedDebtPrimary,
                      primaryCurrency: primaryCurrency,
                      otherCurrenciesText: otherCurrenciesText,
                      onAddDebt: () => context.push("/debts"),
                      onUpdatePlanned: (debtId, amount) {
                        context.read<BudgetController>().updatePlannedDebt(
                          debtId,
                          amount,
                        );
                      },
                      onSave: () => saveBudget(showSuccess: true),
                      showSave: showSave,
                    ),
                    BudgetSummaryTab(
                      plannedExpense: plannedExpenseTotal,
                      plannedIncome: plannedIncomeTotal,
                      plannedDebt: plannedDebtPrimary,
                      estimatedAvailable: estimatedAvailable,
                      primaryCurrency: primaryCurrency,
                      otherDebtCurrenciesText: otherCurrenciesText,
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
}

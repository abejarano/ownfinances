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

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
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
            Text(
              "Orçamento do mês",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            OutlinedButton.icon(
              onPressed: () => _pickMonth(context, date),
              icon: const Icon(Icons.calendar_today),
              label: Text(formatMonth(date)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        InlineSummaryCard(
          title: "Plano do periodo",
          planned: formatMoney(summary?.totals.plannedExpense ?? 0),
          actual: formatMoney(summary?.totals.actualExpense ?? 0),
          remaining: formatMoney(summary?.totals.remainingExpense ?? 0),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "Receitas planejadas: ${formatMoney(summary?.totals.plannedIncome ?? 0)} • Gastos planejados: ${formatMoney(summary?.totals.plannedExpense ?? 0)} • Saldo planejado: ${formatMoney(summary?.totals.plannedNet ?? 0)}",
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (budgetState.isLoading) const LinearProgressIndicator(),
        const SizedBox(height: AppSpacing.sm),
        ...categoriesState.items.map((category) {
          final controller = _controllers.putIfAbsent(category.id, () {
            final initial = budgetState.plannedByCategory[category.id] ?? 0;
            return TextEditingController(
              text: initial > 0 ? formatMoney(initial) : "",
            );
          });
          final planned = budgetState.plannedByCategory[category.id] ?? 0;
          if (planned > 0 && controller.text.isEmpty) {
            controller.text = formatMoney(planned);
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
                  Text(category.name),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: MoneyInput(
                          label: "Planejado",
                          controller: controller,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Atual ${formatMoney(actual)}"),
                          Text(
                            "Restante ${formatMoney(remaining)}",
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          Text(
                            "Progresso ${progressPct.toStringAsFixed(0)}%",
                            style: const TextStyle(color: AppColors.muted),
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
        PrimaryButton(
          label: "Salvar orcamento",
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
              showStandardSnackbar(context, "Orcamento salvo");
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
}

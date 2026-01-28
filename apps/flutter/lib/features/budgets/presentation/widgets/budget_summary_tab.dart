import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_summary_row.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetSummaryTab extends StatelessWidget {
  final double plannedExpense;
  final double plannedIncome;
  final double plannedDebt;
  final double? estimatedAvailable;
  final String primaryCurrency;
  final String? otherDebtCurrenciesText;

  const BudgetSummaryTab({
    super.key,
    required this.plannedExpense,
    required this.plannedIncome,
    required this.plannedDebt,
    required this.estimatedAvailable,
    required this.primaryCurrency,
    required this.otherDebtCurrenciesText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetsSummaryPlanTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                BudgetSummaryRow(
                  label: l10n.budgetsSummaryPlannedExpense,
                  value: formatCurrency(plannedExpense, primaryCurrency),
                ),
                BudgetSummaryRow(
                  label: l10n.budgetsSummaryPlannedIncome,
                  value: formatCurrency(plannedIncome, primaryCurrency),
                ),
                if (estimatedAvailable != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  BudgetSummaryRow(
                    label: l10n.budgetsSummaryEstimatedAvailable,
                    value: formatCurrency(estimatedAvailable!, primaryCurrency),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetsSummaryDebtsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                BudgetSummaryRow(
                  label: l10n.budgetsSummaryPlannedDebts,
                  value: formatCurrency(plannedDebt, primaryCurrency),
                ),
                if (otherDebtCurrenciesText != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "${l10n.budgetsMonthSummaryOtherCurrencies}: $otherDebtCurrenciesText",
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

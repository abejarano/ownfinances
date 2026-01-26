import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_summary_row.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetSummaryTab extends StatelessWidget {
  final double plannedExpense;
  final double actualExpense;
  final int overspentCount;
  final double plannedDebt;
  final int? nextDueDay;
  final String primaryCurrency;
  final VoidCallback onViewCategories;
  final VoidCallback onViewDebts;

  const BudgetSummaryTab({
    super.key,
    required this.plannedExpense,
    required this.actualExpense,
    required this.overspentCount,
    required this.plannedDebt,
    required this.nextDueDay,
    required this.primaryCurrency,
    required this.onViewCategories,
    required this.onViewDebts,
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
                  l10n.budgetsSummaryCategoriesTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                BudgetSummaryRow(
                  label: l10n.budgetsSummaryTotalPlanned,
                  value: formatCurrency(plannedExpense, primaryCurrency),
                ),
                BudgetSummaryRow(
                  label: l10n.budgetsSummaryTotalSpent,
                  value: formatCurrency(actualExpense, primaryCurrency),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.budgetsSummaryOverspentCount(overspentCount),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                  label: l10n.budgetsSummaryViewCategories,
                  onPressed: onViewCategories,
                ),
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
                  label: l10n.budgetsSummaryTotalPlanned,
                  value: formatCurrency(plannedDebt, primaryCurrency),
                ),
                if (nextDueDay != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.budgetsSummaryNextDueDay(nextDueDay!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                  label: l10n.budgetsSummaryViewDebts,
                  onPressed: onViewDebts,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

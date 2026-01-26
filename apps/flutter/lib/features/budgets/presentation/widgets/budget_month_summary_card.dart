import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_summary_row.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetMonthSummaryCard extends StatelessWidget {
  final double plannedCategoryTotal;
  final double plannedDebtPrimary;
  final double totalOutflowPrimary;
  final String primaryCurrency;
  final String? otherCurrenciesText;

  const BudgetMonthSummaryCard({
    super.key,
    required this.plannedCategoryTotal,
    required this.plannedDebtPrimary,
    required this.totalOutflowPrimary,
    required this.primaryCurrency,
    required this.otherCurrenciesText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
          BudgetSummaryRow(
            label: l10n.budgetsMonthSummaryPlannedCategories,
            value: formatCurrency(plannedCategoryTotal, primaryCurrency),
          ),
          BudgetSummaryRow(
            label: l10n.budgetsMonthSummaryPlannedDebts,
            value: formatCurrency(plannedDebtPrimary, primaryCurrency),
          ),
          BudgetSummaryRow(
            label: l10n.budgetsMonthSummaryTotalOutflow,
            value: formatCurrency(totalOutflowPrimary, primaryCurrency),
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
    );
  }
}

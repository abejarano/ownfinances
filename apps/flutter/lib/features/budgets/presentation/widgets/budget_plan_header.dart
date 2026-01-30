import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_summary_item.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetPlanHeader extends StatelessWidget {
  final double totalPlannedExpense;
  final double totalPlannedIncome;
  final String currency;
  final VoidCallback onAdd;

  const BudgetPlanHeader({
    super.key,
    required this.totalPlannedExpense,
    required this.totalPlannedIncome,
    required this.currency,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final balance = totalPlannedIncome - totalPlannedExpense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetsPlanTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.budgetsPlanSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Stats Row
            Row(
              children: [
                // Expenses
                Expanded(
                  flex: 6,
                  child: BudgetSummaryItem(
                    label: l10n.monthSummaryExpenses, // "Salidas"
                    amount: formatCurrency(totalPlannedExpense, currency),
                    color: AppColors.textPrimary,
                    isExpense: true,
                  ),
                ),
                // Income
                Expanded(
                  flex: 6,
                  child: BudgetSummaryItem(
                    label: l10n.monthSummaryIncome, // "Entradas"
                    amount: formatCurrency(totalPlannedIncome, currency),
                    color: AppColors.success,
                    isExpense: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Balance
            BudgetSummaryItem(
              label: l10n.budgetsHeaderBalance,
              amount: formatCurrency(balance, currency),
              color: balance >= 0 ? AppColors.success : AppColors.danger,
              isBold: true,
              alignment: CrossAxisAlignment.center,
            ),

            const SizedBox(height: AppSpacing.md),

            // Helper Text
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.budgetsPlanOnboardingNote, // "No mueve dinero..."
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Add Button
            SecondaryButton(onPressed: onAdd, label: l10n.budgetsPlanAddAction),
          ],
        ),
      ),
    );
  }
}

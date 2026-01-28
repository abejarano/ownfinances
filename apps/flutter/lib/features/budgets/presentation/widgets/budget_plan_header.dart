import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
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
    final balance = totalPlannedIncome - totalPlannedExpense;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.budgetsPlanTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              OutlinedButton.icon(
                label: Text(l10n.budgetsActionAddRecord),
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              // Expenses
              Expanded(
                child: _SummaryItem(
                  label: "Gastos",
                  amount: formatCurrency(totalPlannedExpense, currency),
                  color: AppColors.textPrimary,
                  isExpense: true,
                ),
              ),
              // Income
              Expanded(
                child: _SummaryItem(
                  label: "Ingresos",
                  amount: formatCurrency(totalPlannedIncome, currency),
                  color: AppColors.success,
                  isExpense: false,
                ),
              ),
              // Balance
              Expanded(
                child: _SummaryItem(
                  label: "Balance",
                  amount: formatCurrency(balance, currency),
                  color: balance >= 0 ? AppColors.success : AppColors.danger,
                  isBold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isBold;
  final bool? isExpense;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
    this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    if (isExpense != null) {
      icon = isExpense! ? Icons.arrow_downward : Icons.arrow_upward;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isExpense! ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 2),
            ],
            Text(
              amount,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

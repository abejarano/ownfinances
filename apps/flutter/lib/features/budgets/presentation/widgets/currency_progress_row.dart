import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class CurrencyProgressRow extends StatelessWidget {
  final String currency;
  final double planned;
  final double actual;
  final bool isIncome;
  final AppLocalizations l10n;

  const CurrencyProgressRow({
    super.key,
    required this.currency,
    required this.planned,
    required this.actual,
    required this.isIncome,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final remainingValue = planned - actual;
    final overAmount = actual - planned;
    final isOver = actual > planned;
    final isExactLimit = planned > 0 && actual == planned;

    // Status Logic
    String statusLabel = "";
    String? statusSubtext;
    Color statusColor = AppColors.textSecondary;
    Color barColor = AppColors.borderSoft;

    if (isIncome) {
      if (isOver) {
        statusLabel = l10n.budgetsStatusExceededChip;
        statusSubtext = l10n.budgetsStatusOverText(
          formatCurrency(overAmount, currency),
        );
        statusColor = AppColors.success;
        barColor = AppColors.success;
      } else if (isExactLimit) {
        statusLabel = l10n.budgetsCategoryIncomeStatusAtLimit;
        statusColor = AppColors.success;
        barColor = AppColors.success;
      } else {
        statusLabel = l10n.budgetsCategoryIncomeStatusRemaining(
          formatCurrency(remainingValue, currency),
        );
        statusColor = AppColors.textTertiary;
        barColor = AppColors.success.withValues(alpha: 0.3);
      }
    } else {
      // Expenses
      if (isOver) {
        statusLabel = l10n.budgetsStatusExceededChip;
        statusSubtext = l10n.budgetsStatusOverText(
          formatCurrency(overAmount, currency),
        );
        statusColor = AppColors.danger;
        barColor = AppColors.danger;
      } else if (isExactLimit) {
        statusLabel = l10n.budgetsStatusLimitReached;
        statusColor = AppColors.warning;
        barColor = AppColors.warning;
      } else {
        statusLabel = l10n.budgetsStatusRemainingText(
          formatCurrency(remainingValue, currency),
        );
        statusColor = AppColors.textTertiary; // Calm color
        barColor = AppColors.success; // Green bar for "OK"
      }
    }

    final progressValue = planned <= 0
        ? (actual > 0 ? 1.0 : 0.0)
        : (actual / planned).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currency != "BRL") // Optional: Header for the currency block?
          // Actually, we can just put the currency in the numbers
          // Or maybe a tiny label "USD" above?
          // Let's rely on formatCurrency showing the symbol/code
          const SizedBox.shrink(),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIncome
                      ? l10n.budgetsPlanPlannedIncome
                      : l10n.budgetsPlanPlannedExpense,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  formatCurrency(planned, currency),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isIncome
                      ? l10n.budgetsLabelActualIncome
                      : l10n.budgetsLabelActual,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  formatCurrency(actual, currency),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: AppColors.surface2,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                      color: isOver ? statusColor : AppColors.textSecondary,
                    ),
                  ),
                  if (statusSubtext != null)
                    Text(
                      statusSubtext,
                      style: TextStyle(fontSize: 12, color: statusColor),
                    ),
                ],
              ),
            ),
            if (isOver)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "+${formatCurrency(overAmount, currency)}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

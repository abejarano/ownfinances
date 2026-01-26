import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/core/presentation/components/money_text.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetCategoryCard extends StatelessWidget {
  final Category category;
  final TextEditingController controller;
  final double planned;
  final double actual;
  final Map<String, double> otherCurrencyTotals;
  final VoidCallback onRemove;

  const BudgetCategoryCard({
    super.key,
    required this.category,
    required this.controller,
    required this.planned,
    required this.actual,
    required this.otherCurrencyTotals,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = category.kind == "income";
    final safePlanned = planned;

    if (safePlanned != parseMoney(controller.text)) {
      controller.text = safePlanned > 0 ? formatMoney(safePlanned) : "";
    }

    final plannedValue = safePlanned;
    final actualValue = actual;
    final remainingValue = plannedValue - actualValue;
    final overAmount = actualValue - plannedValue;
    final isOver = actualValue > plannedValue;
    final isExactLimit = plannedValue > 0 && actualValue == plannedValue;
    final isNearLimit = !isOver &&
        !isExactLimit &&
        plannedValue > 0 &&
        actualValue >= plannedValue * 0.75;
    final statusColor = isOver
        ? (isIncome ? AppColors.success : AppColors.danger)
        : isExactLimit
            ? AppColors.primary
            : isNearLimit
                ? AppColors.warning
                : AppColors.success;
    final statusText = isIncome
        ? isOver
            ? l10n.budgetsCategoryIncomeStatusOver(
                formatMoney(overAmount),
              )
            : isExactLimit
                ? l10n.budgetsCategoryIncomeStatusAtLimit
                : isNearLimit
                    ? l10n.budgetsCategoryIncomeStatusNearLimit(
                        formatMoney(remainingValue),
                      )
                    : l10n.budgetsCategoryIncomeStatusRemaining(
                        formatMoney(remainingValue),
                      )
        : isOver
            ? l10n.budgetsCategoryStatusOver(
                formatMoney(overAmount),
              )
            : isExactLimit
                ? l10n.budgetsCategoryStatusAtLimit(
                    formatMoney(remainingValue),
                  )
                : isNearLimit
                    ? l10n.budgetsCategoryStatusNearLimit(
                        formatMoney(remainingValue),
                      )
                    : l10n.budgetsCategoryStatusRemaining(
                        formatMoney(remainingValue),
                      );
    final statusHelper =
        isOver && !isIncome ? l10n.budgetsCategoryStatusOverHelper : null;
    final progressValue = plannedValue <= 0
        ? (actualValue > 0 ? 1.0 : 0.0)
        : (actualValue / plannedValue).clamp(0.0, 1.0);
    final overBadgeColor = isIncome ? AppColors.success : AppColors.danger;
    final overBadgeBackground =
        isIncome ? AppColors.successSoft : AppColors.dangerSoft;
    final otherCurrencyEntries = otherCurrencyTotals.entries
        .where((entry) => entry.value != 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category.name),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "remove") {
                      onRemove();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "remove",
                      child: Text(l10n.budgetsRemoveCategory),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: MoneyInput(
                    label: l10n.budgetsLabelPlanned,
                    controller: controller,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isIncome
                          ? l10n.budgetsLabelActualIncome
                          : l10n.budgetsLabelActual,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    MoneyText(
                      value: actual,
                      variant: MoneyTextVariant.l,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ],
            ),
            if (otherCurrencyEntries.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final entry in otherCurrencyEntries)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Text(
                        formatCurrency(entry.value, entry.key),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            if (statusHelper != null) ...[
              const SizedBox(height: 2),
              Text(
                statusHelper,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: AppColors.borderSoft,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        statusColor,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                if (isOver) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: overBadgeBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "+${formatMoney(overAmount)}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: overBadgeColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

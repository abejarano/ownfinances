import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetPlanCategoryCard extends StatelessWidget {
  final Category category;
  final double plannedExpense;
  final double plannedIncome;
  final double actualPrimary;
  final Map<String, double> otherCurrencyTotals;
  final String primaryCurrency;
  final VoidCallback onOpenDetails;
  final VoidCallback onAddAnother;
  final VoidCallback onRemoveCategory;

  const BudgetPlanCategoryCard({
    super.key,
    required this.category,
    required this.plannedExpense,
    required this.plannedIncome,
    required this.actualPrimary,
    required this.otherCurrencyTotals,
    required this.primaryCurrency,
    required this.onOpenDetails,
    required this.onAddAnother,
    required this.onRemoveCategory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = category.kind == "income";
    final plannedValue = isIncome ? plannedIncome : plannedExpense;
    final actualValue = actualPrimary;

    final remainingValue = plannedValue - actualValue;
    final overAmount = actualValue - plannedValue;
    final isOver = actualValue > plannedValue;
    final isExactLimit = plannedValue > 0 && actualValue == plannedValue;

    // Status Logic
    String statusLabel = "";
    String? statusSubtext;
    Color statusColor = AppColors.textSecondary;
    Color barColor = AppColors.borderSoft;

    if (isIncome) {
      if (isOver) {
        statusLabel = l10n.budgetsStatusExceededChip;
        statusSubtext = l10n.budgetsStatusOverText(
          formatCurrency(overAmount, primaryCurrency),
        );
        statusColor = AppColors.success;
        barColor = AppColors.success;
      } else if (isExactLimit) {
        statusLabel = l10n.budgetsCategoryIncomeStatusAtLimit;
        statusColor = AppColors.success;
        barColor = AppColors.success;
      } else {
        statusLabel = l10n.budgetsCategoryIncomeStatusRemaining(
          formatCurrency(remainingValue, primaryCurrency),
        );
        statusColor = AppColors.textTertiary;
        barColor = AppColors.success.withOpacity(0.3);
      }
    } else {
      // Expenses
      if (isOver) {
        statusLabel = l10n.budgetsStatusExceededChip;
        statusSubtext = l10n.budgetsStatusOverText(
          formatCurrency(overAmount, primaryCurrency),
        );
        statusColor = AppColors.danger;
        barColor = AppColors.danger;
      } else if (isExactLimit) {
        statusLabel = l10n.budgetsStatusLimitReached;
        statusColor = AppColors.warning;
        barColor = AppColors.warning;
      } else {
        statusLabel = l10n.budgetsStatusRemainingText(
          formatCurrency(remainingValue, primaryCurrency),
        );
        statusColor = AppColors.textTertiary; // Calm color
        barColor = AppColors.success; // Green bar for "OK"
      }
    }

    final progressValue = plannedValue <= 0
        ? (actualValue > 0 ? 1.0 : 0.0)
        : (actualValue / plannedValue).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.borderSoft.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpenDetails,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon, Name, Action
              Row(
                children: [
                  _CategoryIcon(iconName: category.icon),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    onSelected: (value) {
                      if (value == "view") onOpenDetails();
                      if (value == "add") onAddAnother();
                      if (value == "remove") onRemoveCategory();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "view",
                        child: Text(l10n.budgetsPlanDetailsAction),
                      ),
                      PopupMenuItem(
                        value: "add",
                        child: Text(l10n.budgetsPlanAddAnotherAction),
                      ),
                      PopupMenuItem(
                        value: "remove",
                        child: Text(l10n.budgetsRemoveCategory),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Planned vs Actual Numbers
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
                        formatCurrency(plannedValue, primaryCurrency),
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
                        formatCurrency(actualValue, primaryCurrency),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Progress Bar
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

              // Status Text & Chip
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
                            fontWeight: isOver
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isOver
                                ? statusColor
                                : AppColors.textSecondary,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "+${formatCurrency(overAmount, primaryCurrency)}",
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
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String? iconName;

  const _CategoryIcon({required this.iconName});

  @override
  Widget build(BuildContext context) {
    final iconData = _resolveIcon(iconName);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, size: 16, color: AppColors.textPrimary),
    );
  }

  IconData _resolveIcon(String? iconName) {
    if (iconName == null) return Icons.category;
    const map = {
      "salary": Icons.attach_money,
      "restaurant": Icons.restaurant,
      "home": Icons.home,
      "transport": Icons.directions_car,
      "leisure": Icons.movie,
      "health": Icons.medical_services,
      "shopping": Icons.shopping_bag,
      "bills": Icons.receipt_long,
      "entertainment": Icons.sports_esports,
      "education": Icons.school,
      "gym": Icons.fitness_center,
      "travel": Icons.flight,
      "gift": Icons.card_giftcard,
      "investment": Icons.trending_up,
      "family": Icons.family_restroom,
    };
    return map[iconName] ?? Icons.category;
  }
}

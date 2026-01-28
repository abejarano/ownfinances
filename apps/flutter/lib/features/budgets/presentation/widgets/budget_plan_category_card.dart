import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/category_icon.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/l10n/app_localizations.dart";
import "package:ownfinances/features/budgets/presentation/widgets/currency_progress_row.dart";

class BudgetPlanCategoryCard extends StatelessWidget {
  final Category category;
  final Map<String, double> plannedTotal;
  final Map<String, double> actualTotal;
  final String primaryCurrency;
  final VoidCallback onOpenDetails;
  final VoidCallback onAddAnother;
  final VoidCallback onRemoveCategory;

  const BudgetPlanCategoryCard({
    super.key,
    required this.category,
    required this.plannedTotal,
    required this.actualTotal,
    required this.primaryCurrency,
    required this.onOpenDetails,
    required this.onAddAnother,
    required this.onRemoveCategory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Identify all currencies involved
    final allCurrencies = {
      ...plannedTotal.keys,
      ...actualTotal.keys,
      primaryCurrency, // Always include primary so it shows up even if empty
    };

    // Sort: Primary first, then others alphabetical
    final sortedCurrencies = allCurrencies.toList()
      ..sort((a, b) {
        if (a == primaryCurrency) return -1;
        if (b == primaryCurrency) return 1;
        return a.compareTo(b);
      });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.borderSoft.withValues(alpha: 0.5)),
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
              // Header
              Row(
                children: [
                  CategoryIcon(
                    iconName: category.icon,
                    categoryKind: category.kind,
                    size: 40,
                  ),
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

              // Render a section for each currency
              for (final currency in sortedCurrencies) ...[
                Builder(
                  builder: (context) {
                    final planned = plannedTotal[currency] ?? 0.0;
                    final actual = actualTotal[currency] ?? 0.0;

                    // Skip if both zero (unless it's primary currency, we might want to show empty state?)
                    // Actually, if it's primary and zeros, we usually keep it to show "0/0" placeholder
                    // But if user has NO plan and NO actual in primary, but has USD, maybe we hide primary?
                    // Let's hide if both zero, UNLESS it's the ONLY currency
                    if (planned == 0 &&
                        actual == 0 &&
                        sortedCurrencies.length > 1) {
                      return const SizedBox.shrink();
                    }

                    return CurrencyProgressRow(
                      currency: currency,
                      planned: planned,
                      actual: actual,
                      isIncome: category.kind == "income",
                      l10n: l10n,
                    );
                  },
                ),
                if (currency != sortedCurrencies.last)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_category_card.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_empty_state.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetCategoriesTab extends StatelessWidget {
  final bool isLoading;
  final bool hasBudget;
  final List<Category> categories;
  final Map<String, TextEditingController> controllers;
  final Map<String, CategorySummary> summaryMap;
  final Map<String, double> plannedByCategory;
  final String primaryCurrency;
  final VoidCallback onCreateBudget;
  final void Function(String categoryId) onRemoveCategory;
  final VoidCallback onSave;
  final bool showSave;

  const BudgetCategoriesTab({
    super.key,
    required this.isLoading,
    required this.hasBudget,
    required this.categories,
    required this.controllers,
    required this.summaryMap,
    required this.plannedByCategory,
    required this.primaryCurrency,
    required this.onCreateBudget,
    required this.onRemoveCategory,
    required this.onSave,
    required this.showSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            showSave ? 96 : AppSpacing.md,
          ),
          children: [
            if (isLoading) const LinearProgressIndicator(),
            if (!isLoading)
              if (!hasBudget)
                BudgetEmptyState(
                  onCreate: onCreateBudget,
                )
              else ...[
                for (int index = 0; index < categories.length; index++) ...[
                  Builder(
                    builder: (context) {
                      final category = categories[index];
                      final controller = controllers.putIfAbsent(
                        category.id,
                        () => TextEditingController(),
                      );
                      final planned =
                          plannedByCategory[category.id] ?? 0.0;
                      final actualByCurrency =
                          summaryMap[category.id]?.actualByCurrency ?? {};
                      final actualPrimary =
                          actualByCurrency[primaryCurrency] ?? 0.0;
                      final otherCurrencyTotals =
                          Map<String, double>.fromEntries(
                        actualByCurrency.entries.where(
                          (entry) =>
                              entry.key != primaryCurrency &&
                              entry.value != 0,
                        ),
                      );

                      return BudgetCategoryCard(
                        category: category,
                        controller: controller,
                        planned: planned,
                        actual: actualPrimary,
                        otherCurrencyTotals: otherCurrencyTotals,
                        onRemove: () => onRemoveCategory(category.id),
                      );
                    },
                  ),
                  if (index < categories.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
          ],
        ),
        if (showSave)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: l10n.budgetsSaveCategoriesButton,
                onPressed: onSave,
              ),
            ),
          ),
      ],
    );
  }
}

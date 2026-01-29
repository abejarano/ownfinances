import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetCategoryDetailSheet extends StatelessWidget {
  final Category category;
  final List<BudgetPlanEntry> entries;
  final String primaryCurrency;
  final void Function(String entryId) onRemoveEntry;
  final VoidCallback onAddAnother;

  const BudgetCategoryDetailSheet({
    super.key,
    required this.category,
    required this.entries,
    required this.primaryCurrency,
    required this.onRemoveEntry,
    required this.onAddAnother,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = category.kind == "income";
    final total = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    final plannedExpense = isIncome ? 0.0 : total;
    final plannedIncome = isIncome ? total : 0.0;

    final summaryCurrency = entries.isNotEmpty
        ? entries.first.currency
        : primaryCurrency;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.budgetsPlanCategoryDetailTitle(category.name),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (plannedExpense > 0)
                _SummaryRow(
                  label: l10n.budgetsPlanPlannedExpense,
                  value: formatCurrency(plannedExpense, summaryCurrency),
                ),
              if (plannedIncome > 0)
                _SummaryRow(
                  label: l10n.budgetsPlanPlannedIncome,
                  value: formatCurrency(plannedIncome, summaryCurrency),
                ),
              const SizedBox(height: AppSpacing.sm),
              if (entries.isEmpty)
                Text(
                  l10n.budgetsPlanEmptyCategoryDetail,
                  style: const TextStyle(color: AppColors.textTertiary),
                )
              else
                Column(
                  children: [
                    for (final entry in entries) ...[
                      _EntryRow(
                        entry: entry,
                        currency: entry.currency,
                        typeLabel: isIncome
                            ? l10n.budgetsPlanTypeIncome
                            : l10n.budgetsPlanTypeExpense,
                        typeColor: isIncome
                            ? AppColors.success
                            : AppColors.warning,
                        onRemove: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              content: Text(
                                l10n.budgetsEntryDialogDeleteConfirm,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text(
                                    "Cancelar",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    onRemoveEntry(entry.id);
                                  },
                                  child: Text(
                                    l10n.budgetsEntryDialogDeleteAction,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (entry != entries.last)
                        const Divider(height: AppSpacing.md),
                    ],
                  ],
                ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: l10n.budgetsPlanAddAnotherAction,
                onPressed: onAddAnother,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final BudgetPlanEntry entry;
  final String currency;
  final String typeLabel;
  final Color typeColor;
  final VoidCallback onRemove;

  const _EntryRow({
    required this.entry,
    required this.currency,
    required this.typeLabel,
    required this.typeColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            typeLabel,
            style: TextStyle(
              color: typeColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatCurrency(entry.amount, currency),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (entry.description != null &&
                  entry.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  entry.description!,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline, size: 20),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

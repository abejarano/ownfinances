import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/budgets/domain/entities/budget.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_category_detail_sheet.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_plan_category_card.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_plan_header.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_smart_add_modal.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetCategoriesTab extends StatefulWidget {
  final bool isLoading;
  final bool isOnboarding;
  final bool showSnapshotPrompt;
  final List<Category> categories;
  final List<BudgetCategoryPlan> planCategories;
  final Map<String, CategorySummary> summaryMap;
  final String primaryCurrency;
  final VoidCallback onApplySnapshot;
  final VoidCallback onStartFresh;
  final Future<String?> Function(
    String categoryId,
    double amount,

    String currency,
    String? description,
  )
  onAddEntry;
  final void Function(String entryId) onRemoveEntry;
  final void Function(String categoryId) onRemoveCategory;
  final Future<String?> Function() onSave;
  final Future<String?> Function() onSaveEntry;
  final bool canSave;
  final bool showSave;

  const BudgetCategoriesTab({
    super.key,
    required this.isLoading,
    required this.isOnboarding,
    required this.showSnapshotPrompt,
    required this.categories,
    required this.planCategories,
    required this.summaryMap,
    required this.primaryCurrency,
    required this.onApplySnapshot,
    required this.onStartFresh,
    required this.onAddEntry,
    required this.onRemoveEntry,
    required this.onRemoveCategory,
    required this.onSave,
    required this.onSaveEntry,
    required this.canSave,
    this.showSave = true,
  });

  @override
  State<BudgetCategoriesTab> createState() => _BudgetCategoriesTabState();
}

class _BudgetCategoriesTabState extends State<BudgetCategoriesTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openSmartAddModal([String? initialCategoryId]) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return BudgetSmartAddModal(
          categories: widget.categories,
          primaryCurrency: widget.primaryCurrency,
          onSubmit: (categoryId, amount, currency, description) async {
            final error = await widget.onAddEntry(
              categoryId,
              amount,
              currency,
              description,
            );
            if (!mounted) return;
            if (error != null) {
              throw error; // Let the modal handle error UI or rethrow
            }
            showStandardSnackbar(context, l10n.budgetsModalConfirmAdded);
          },
        );
      },
    );
  }

  void _openCategoryDetail(Category category, List<BudgetPlanEntry> entries) {
    final localEntries = List<BudgetPlanEntry>.from(entries);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BudgetCategoryDetailSheet(
              category: category,
              entries: localEntries,
              primaryCurrency: widget.primaryCurrency,
              onRemoveEntry: (entryId) {
                widget.onRemoveEntry(entryId);
                setModalState(() {
                  localEntries.removeWhere((entry) => entry.id == entryId);
                });
              },
              onAddAnother: () {
                Navigator.of(context).pop();
                // We delay slightly to allow bottom sheet to close
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) _openSmartAddModal(category.id);
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoryById = {
      for (final category in widget.categories) category.id: category,
    };
    final planItems =
        widget.planCategories
            .map(
              (plan) => _PlanItem(
                plan: plan,
                category: categoryById[plan.categoryId],
              ),
            )
            .where((item) => item.category != null)
            .toList()
          ..sort((a, b) => a.category!.name.compareTo(b.category!.name));

    final hasPlanItems = planItems.isNotEmpty;

    // Calculate totals for Header (State B)
    double totalExpense = 0.0;
    double totalIncome = 0.0;
    for (final item in planItems) {
      final amount = item.plan.plannedTotal[widget.primaryCurrency] ?? 0.0;
      if (item.category!.kind == "income") {
        totalIncome += amount;
      } else {
        totalExpense += amount;
      }
    }

    return Stack(
      children: [
        Column(
          children: [
            if (widget.isLoading) const LinearProgressIndicator(minHeight: 2),

            // STATE B: Header moved to ListView
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  widget.showSave ? 96 : AppSpacing.md,
                ),
                children: [
                  // STATE A: Empty State Banner
                  if (!hasPlanItems)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.budgetsPlanTitle, // "Plan del mes"
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.budgetsPlanOnboardingSubtitle, // "Registra lo que planeas..."
                                        style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            PrimaryButton(
                              label: l10n
                                  .budgetsPlanEmptyAction, // "Agregar primer registro"
                              onPressed: () => _openSmartAddModal(),
                              fullWidth: true,
                            ),
                            if (widget.showSnapshotPrompt) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Center(
                                child: TextButton(
                                  onPressed: widget.onApplySnapshot,
                                  child: Text(l10n.budgetsSnapshotApplyAction),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // STATE B: Header (now scrollable)
                    BudgetPlanHeader(
                      totalPlannedExpense: totalExpense,
                      totalPlannedIncome: totalIncome,
                      currency: widget.primaryCurrency,
                      onAdd: () => _openSmartAddModal(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // List of Categories
                    for (int index = 0; index < planItems.length; index++) ...[
                      Builder(
                        builder: (context) {
                          final item = planItems[index];
                          final category = item.category!;
                          final plannedTotal = item.plan.plannedTotal;
                          final actualByCurrency =
                              widget
                                  .summaryMap[category.id]
                                  ?.actualByCurrency ??
                              {};

                          return BudgetPlanCategoryCard(
                            category: category,
                            plannedTotal: plannedTotal,
                            actualTotal: actualByCurrency,
                            primaryCurrency: widget.primaryCurrency,
                            onOpenDetails: () => _openCategoryDetail(
                              category,
                              item.plan.entries,
                            ),
                            onAddAnother: () => _openSmartAddModal(category.id),
                            onRemoveCategory: () =>
                                widget.onRemoveCategory(category.id),
                          );
                        },
                      ),
                      if (index < planItems.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
        if (widget.showSave)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: l10n.budgetsSaveCategoriesButton,
                onPressed: widget.canSave
                    ? () async {
                        await widget.onSave();
                      }
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanItem {
  final BudgetCategoryPlan plan;
  final Category? category;

  const _PlanItem({required this.plan, required this.category});
}

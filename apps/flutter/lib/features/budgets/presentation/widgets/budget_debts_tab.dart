import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/buttons.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/core/utils/formatters.dart';
import 'package:ownfinances/features/budgets/application/controllers/budget_controller.dart';
import 'package:ownfinances/features/budgets/domain/entities/budget.dart';
import 'package:ownfinances/features/budgets/presentation/widgets/budget_debt_add_modal.dart';
import 'package:ownfinances/features/budgets/presentation/widgets/budget_debt_plan_card.dart';
import 'package:ownfinances/features/budgets/presentation/widgets/budget_summary_item.dart';
import 'package:ownfinances/features/debts/domain/entities/debt.dart';
import 'package:ownfinances/features/debts/domain/entities/debt_summary.dart';
import 'package:ownfinances/features/reports/application/controllers/reports_controller.dart';
import 'package:ownfinances/l10n/app_localizations.dart';

class BudgetDebtsTab extends StatelessWidget {
  final bool isLoading;
  final List<Debt> debts; // Active debts
  final Map<String, BudgetDebtPlan> plannedByDebt;
  final Map<String, DebtSummary> summaries;
  final double plannedDebtPrimary;
  final String primaryCurrency;
  final String? otherCurrenciesText;

  final VoidCallback onAddDebt;
  final bool canSave;
  final bool showSave;
  final Future<void> Function()? onSave;

  const BudgetDebtsTab({
    super.key,
    required this.isLoading,
    required this.debts,
    required this.plannedByDebt,
    required this.summaries,
    required this.plannedDebtPrimary,
    required this.primaryCurrency,
    this.otherCurrenciesText,
    required this.onAddDebt,
    this.canSave = false,
    this.showSave = false,
    this.onSave,
  });

  void _openAddValueModal(BuildContext context, {BudgetDebtPlan? plan}) {
    final reportsState = context.read<ReportsController>().state;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => BudgetDebtAddModal(
        period: reportsState.period,
        date: reportsState.date,
        initialPlan: plan,
      ),
    );
  }

  void _removePayment(BuildContext context, String debtId) {
    // Setting amount to 0 effectively removes it based on our controller logic
    final plan = BudgetDebtPlan(debtId: debtId, plannedAmount: 0);
    context.read<BudgetController>().setPlannedDebt(plan);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Group totals by currency
    final totalsByCurrency = <String, double>{};
    for (final plan in plannedByDebt.values) {
      if (plan.plannedAmount <= 0) continue;
      final debt = debts.cast<Debt?>().firstWhere(
        (d) => d?.id == plan.debtId,
        orElse: () => null,
      );
      if (debt != null) {
        totalsByCurrency[debt.currency] =
            (totalsByCurrency[debt.currency] ?? 0) + plan.plannedAmount;
      }
    }

    // Format totals string
    final totalsEntries = totalsByCurrency.entries.toList();

    totalsEntries.sort((a, b) {
      if (a.key == primaryCurrency) return -1;
      if (b.key == primaryCurrency) return 1;
      return 0;
    });

    final hasPlans = plannedByDebt.values.any((p) => p.plannedAmount > 0);

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  showSave ? 96 : 80,
                ),
                children: [
                  // Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.budgetsDebtPlannedTitle,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.budgetsDebtPlannedSubtitle,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.textTertiary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Totals
                          if (totalsEntries.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                                top: AppSpacing.md,
                              ),
                              child: Wrap(
                                spacing: AppSpacing.lg,
                                runSpacing: AppSpacing.md,
                                children: totalsEntries.map((e) {
                                  return BudgetSummaryItem(
                                    label:
                                        "${l10n.budgetsDebtQuickTotal} (${e.key})",
                                    amount: formatCurrency(e.value, e.key),
                                    color: AppColors.textPrimary,
                                    isExpense: true,
                                  );
                                }).toList(),
                              ),
                            )
                          else
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
                                  l10n.budgetsDebtPlannedHelper,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Add Payment Button
                          SecondaryButton(
                            onPressed: () => _openAddValueModal(context),
                            label: l10n.budgetsDebtActionAdd,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // List or Empty
                  if (!hasPlans)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.money_off,
                                size: 24,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.budgetsDebtEmptyState,
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // List of Plan Cards
                    Builder(
                      builder: (context) {
                        final plans = plannedByDebt.values.toList();
                        // Sort plans by debt name
                        plans.sort((a, b) {
                          final debtA = debts.cast<Debt?>().firstWhere(
                            (d) => d?.id == a.debtId,
                            orElse: () => null,
                          );
                          final debtB = debts.cast<Debt?>().firstWhere(
                            (d) => d?.id == b.debtId,
                            orElse: () => null,
                          );
                          return (debtA?.name ?? '').compareTo(
                            debtB?.name ?? '',
                          );
                        });

                        return Column(
                          children: plans.where((p) => p.plannedAmount > 0).map(
                            (plan) {
                              final debt = debts.cast<Debt?>().firstWhere(
                                (d) => d?.id == plan.debtId,
                                orElse: () => null,
                              );
                              if (debt == null) return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: BudgetDebtPlanCard(
                                  plan: plan,
                                  debt: debt,
                                  summary: summaries[debt.id],
                                  onEdit: () =>
                                      _openAddValueModal(context, plan: plan),
                                  onRemove: () =>
                                      _removePayment(context, plan.debtId),
                                ),
                              );
                            },
                          ).toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
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
                label: l10n.budgetsSaveDebtsButton,
                onPressed: canSave && onSave != null
                    ? () async {
                        await onSave!();
                      }
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

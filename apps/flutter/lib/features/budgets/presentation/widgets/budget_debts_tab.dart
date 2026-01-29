import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/buttons.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/core/utils/formatters.dart';
import 'package:ownfinances/features/budgets/application/controllers/budget_controller.dart';
import 'package:ownfinances/features/budgets/domain/entities/budget.dart';
import 'package:ownfinances/features/budgets/presentation/widgets/budget_debt_add_modal.dart';
import 'package:ownfinances/features/budgets/presentation/widgets/budget_debt_plan_card.dart';
import 'package:ownfinances/features/debts/domain/entities/debt.dart';
import 'package:ownfinances/features/debts/domain/entities/debt_summary.dart';
import 'package:ownfinances/features/reports/application/controllers/reports_controller.dart';
import 'package:ownfinances/l10n/app_localizations.dart';

class BudgetDebtsTab extends StatelessWidget {
  final bool isLoading;
  final List<Debt> debts; // Active debts
  final Map<String, BudgetDebtPayment> plannedByDebt;
  final Map<String, DebtSummary> summaries;
  final double plannedDebtPrimary;
  final String primaryCurrency;
  final String? otherCurrenciesText;

  final VoidCallback onAddDebt;

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
  });

  void _openAddValueModal(BuildContext context, {BudgetDebtPayment? payment}) {
    final reportsState = context.read<ReportsController>().state;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => BudgetDebtAddModal(
        period: reportsState.period,
        date: reportsState.date,
        initialPayment: payment,
      ),
    );
  }

  void _removePayment(BuildContext context, String debtId) {
    // Setting amount to 0 effectively removes it based on our controller logic
    final payment = BudgetDebtPayment(debtId: debtId, amount: 0);
    context.read<BudgetController>().setPlannedDebt(payment);
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
    for (final payment in plannedByDebt.values) {
      if (payment.amount <= 0) continue;
      final debt = debts.cast<Debt?>().firstWhere(
        (d) => d?.id == payment.debtId,
        orElse: () => null,
      );
      if (debt != null) {
        totalsByCurrency[debt.currency] =
            (totalsByCurrency[debt.currency] ?? 0) + payment.amount;
      }
    }

    // Format totals string
    final totalsList = totalsByCurrency.entries.map((e) {
      return formatCurrency(e.value, e.key);
    }).toList();

    totalsList.sort((a, b) {
      if (a.contains(primaryCurrency)) return -1;
      if (b.contains(primaryCurrency)) return 1;
      return 0;
    });
    final totalsString = totalsList.join("  ·  ");

    final hasPayments = plannedByDebt.values.any((p) => p.amount > 0);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.budgetsDebtPlannedSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Totals
                if (totalsString.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.md,
                      top: AppSpacing.md,
                    ),
                    child: Text(
                      totalsString,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
        if (!hasPayments)
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
              final payments = plannedByDebt.values.toList();
              // Sort payments by debt name
              payments.sort((a, b) {
                final debtA = debts.cast<Debt?>().firstWhere(
                  (d) => d?.id == a.debtId,
                  orElse: () => null,
                );
                final debtB = debts.cast<Debt?>().firstWhere(
                  (d) => d?.id == b.debtId,
                  orElse: () => null,
                );
                return (debtA?.name ?? '').compareTo(debtB?.name ?? '');
              });

              return Column(
                children: payments.where((p) => p.amount > 0).map((payment) {
                  final debt = debts.cast<Debt?>().firstWhere(
                    (d) => d?.id == payment.debtId,
                    orElse: () => null,
                  );
                  if (debt == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: BudgetDebtPlanCard(
                      payment: payment,
                      debt: debt,
                      summary: summaries[debt.id],
                      onEdit: () =>
                          _openAddValueModal(context, payment: payment),
                      onRemove: () => _removePayment(context, payment.debtId),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],

        // Bottom padding
        const SizedBox(height: 80),
      ],
    );
  }
}

import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_summary_row.dart";
import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/features/debts/domain/entities/debt_summary.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetDebtPlannedCard extends StatelessWidget {
  final List<Debt> debts;
  final Map<String, double> plannedByDebt;
  final Map<String, DebtSummary> summaries;
  final Map<String, TextEditingController> controllers;
  final double plannedDebtPrimary;
  final String primaryCurrency;
  final String? otherCurrenciesText;
  final VoidCallback onAddDebt;
  final void Function(String debtId, double amount) onUpdatePlanned;

  const BudgetDebtPlannedCard({
    super.key,
    required this.debts,
    required this.plannedByDebt,
    required this.summaries,
    required this.controllers,
    required this.plannedDebtPrimary,
    required this.primaryCurrency,
    required this.otherCurrenciesText,
    required this.onAddDebt,
    required this.onUpdatePlanned,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    void updatePlanned(Debt debt, double value) {
      onUpdatePlanned(debt.id, value);
      final controller = controllers[debt.id];
      if (controller == null) return;
      controller.text = value > 0
          ? formatMoney(
              value,
              symbol: debt.currency,
            )
          : "";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetsDebtPlannedTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                BudgetSummaryRow(
                  label: l10n.budgetsDebtTotalPlannedLabel(primaryCurrency),
                  value: formatCurrency(plannedDebtPrimary, primaryCurrency),
                ),
                if (otherCurrenciesText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      "${l10n.budgetsMonthSummaryOtherCurrencies}: $otherCurrenciesText",
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.budgetsDebtPaymentNote,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (debts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.budgetsDebtEmptyState,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: onAddDebt,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.debtsActionAdd),
                  ),
                ],
              ),
            ),
          )
        else ...[
          for (final debt in debts) ...[
            Builder(
              builder: (context) {
                final planned = plannedByDebt[debt.id] ?? 0;
                final controller = controllers.putIfAbsent(
                  debt.id,
                  () => TextEditingController(
                    text: planned > 0
                        ? formatMoney(
                            planned,
                            symbol: debt.currency,
                          )
                        : "",
                  ),
                );
                if (planned != parseMoney(controller.text)) {
                  controller.text = planned > 0
                      ? formatMoney(
                          planned,
                          symbol: debt.currency,
                        )
                      : "";
                }

                final summary = summaries[debt.id];
                final paid = summary?.paymentsThisMonth ?? 0;
                String? progressText;
                String? progressHelper;
                if (planned > 0 || paid > 0) {
                  progressText = l10n.budgetsDebtPaidPlanned(
                    formatCurrency(paid, debt.currency),
                    formatCurrency(planned, debt.currency),
                  );
                  if (paid > planned) {
                    progressHelper = l10n.budgetsDebtOverpaid(
                      formatCurrency(
                        paid - planned,
                        debt.currency,
                      ),
                    );
                  } else if (paid < planned) {
                    progressHelper = l10n.budgetsDebtRemaining(
                      formatCurrency(
                        planned - paid,
                        debt.currency,
                      ),
                    );
                  }
                }

                String? minWarning;
                if (debt.minimumPayment != null &&
                    debt.minimumPayment! > 0 &&
                    planned < debt.minimumPayment!) {
                  minWarning = l10n.budgetsDebtMinimumWarning;
                }
                final overpayWarning =
                    debt.amountDue > 0 && planned > debt.amountDue
                        ? l10n.budgetsDebtOverpayWarning
                        : null;

                final dueLabel = debt.dueDay != null
                    ? l10n.debtsDueDayLabel(debt.dueDay!)
                    : null;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                debt.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (dueLabel != null)
                              Text(
                                dueLabel,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${l10n.budgetsDebtOweLabel}: ${formatCurrency(debt.amountDue, debt.currency)}",
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MoneyInput(
                          label: l10n.budgetsDebtPayLabel,
                          controller: controller,
                          helperText: overpayWarning ?? minWarning,
                          currencySymbol: debt.currency,
                        ),
                        if (debt.minimumPayment != null ||
                            debt.amountDue > 0) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              if (debt.minimumPayment != null &&
                                  debt.minimumPayment! > 0)
                                TextButton(
                                  onPressed: () => updatePlanned(
                                    debt,
                                    debt.minimumPayment!,
                                  ),
                                  child: Text(l10n.budgetsDebtQuickMin),
                                ),
                              if (debt.amountDue > 0)
                                TextButton(
                                  onPressed: () => updatePlanned(
                                    debt,
                                    debt.amountDue,
                                  ),
                                  child: Text(l10n.budgetsDebtQuickTotal),
                                ),
                            ],
                          ),
                        ],
                        if (progressText != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            progressText,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (progressHelper != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            progressHelper,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            if (debt != debts.last) const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  for (final debt in debts) {
                    onUpdatePlanned(debt.id, 0.0);
                    final controller = controllers[debt.id];
                    if (controller != null) {
                      controller.text = "";
                    }
                  }
                },
                child: Text(l10n.budgetsDebtActionZeroAll),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  for (final debt in debts) {
                    final suggested = debt.minimumPayment != null &&
                            debt.minimumPayment! > 0
                        ? debt.minimumPayment!
                        : (debt.amountDue > 0 ? debt.amountDue : 0.0);
                    updatePlanned(debt, suggested);
                  }
                },
                child: Text(l10n.budgetsDebtActionSuggest),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_debt_planned_card.dart";
import "package:ownfinances/features/budgets/presentation/widgets/budget_empty_state.dart";
import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/features/debts/domain/entities/debt_summary.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetDebtsTab extends StatelessWidget {
  final bool isLoading;
  final bool hasBudget;
  final List<Debt> debts;
  final Map<String, double> plannedByDebt;
  final Map<String, DebtSummary> summaries;
  final Map<String, TextEditingController> controllers;
  final double plannedDebtPrimary;
  final String primaryCurrency;
  final String? otherCurrenciesText;
  final VoidCallback onAddDebt;
  final void Function(String debtId, double amount) onUpdatePlanned;
  final VoidCallback onCreateBudget;
  final VoidCallback onSave;
  final bool showSave;

  const BudgetDebtsTab({
    super.key,
    required this.isLoading,
    required this.hasBudget,
    required this.debts,
    required this.plannedByDebt,
    required this.summaries,
    required this.controllers,
    required this.plannedDebtPrimary,
    required this.primaryCurrency,
    required this.otherCurrenciesText,
    required this.onAddDebt,
    required this.onUpdatePlanned,
    required this.onCreateBudget,
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
              else
                BudgetDebtPlannedCard(
                  debts: debts,
                  plannedByDebt: plannedByDebt,
                  summaries: summaries,
                  controllers: controllers,
                  plannedDebtPrimary: plannedDebtPrimary,
                  primaryCurrency: primaryCurrency,
                  otherCurrenciesText: otherCurrenciesText,
                  onAddDebt: onAddDebt,
                  onUpdatePlanned: onUpdatePlanned,
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
                onPressed: onSave,
              ),
            ),
          ),
      ],
    );
  }
}

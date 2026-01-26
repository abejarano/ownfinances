import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/money_text.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onCharge;
  final VoidCallback onPayment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onHistory;

  const DebtCard({
    super.key,
    required this.debt,
    required this.onCharge,
    required this.onPayment,
    required this.onEdit,
    required this.onDelete,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Due Date Logic
    final dueLabel = debt.dueDay != null
        ? AppLocalizations.of(context)!.debtsDueDayLabel(debt.dueDay!)
        : null;

    // 2. Main Number Logic
    Widget balanceWidget;
    if (debt.amountDue > 0) {
      balanceWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.debtsCurrentBill,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          MoneyText(
            value: debt.amountDue,
            symbol: debt.currency,
            color: AppColors.danger,
            variant: MoneyTextVariant.l,
          ),
        ],
      );
    } else if (debt.creditBalance > 0) {
      balanceWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.debtsAvailableCredit,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          MoneyText(
            value: debt.creditBalance,
            symbol: debt.currency,
            color: AppColors.success,
            variant: MoneyTextVariant.l,
          ),
        ],
      );
    } else {
      balanceWidget = Text(
        AppLocalizations.of(context)!.debtsAllPaid,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (dueLabel != null)
                        Text(
                          dueLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onHistory,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == "edit") onEdit();
                    if (value == "delete") onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 16),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.commonEdit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete,
                            size: 16,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.commonDelete,
                            style: const TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            // Balance
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [Expanded(child: balanceWidget)]),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: AppLocalizations.of(context)!.debtsActionCharge,
                    onPressed: onCharge,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: AppLocalizations.of(context)!.debtsActionPay,
                    icon: Icons.check,
                    onPressed: onPayment,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

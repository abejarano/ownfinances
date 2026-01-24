import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/money_text.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/currency_utils.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";
import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class CreditCardAccountCard extends StatelessWidget {
  final Account account;
  final Debt? debt;
  final VoidCallback onEdit;
  final VoidCallback onViewDebts;

  const CreditCardAccountCard({
    super.key,
    required this.account,
    required this.debt,
    required this.onEdit,
    required this.onViewDebts,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = debt?.currency ?? account.currency;
    final isCurrencyValid = CurrencyUtils.isValidCurrency(currency);
    final dueDay = debt?.dueDay;
    final amountDue = debt?.amountDue ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Chip + Edit Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.accountsCardChip,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit,
                  size: 20,
                  color: AppColors.primary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.accountsCardCurrentBill,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 4),
          MoneyText(
            value: amountDue,
            symbol: currency,
            color: AppColors.danger,
            variant: MoneyTextVariant.l,
          ),
          if (dueDay != null) ...[
            const SizedBox(height: 6),
            Text(
              l10n.debtsDueDayLabel(dueDay),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: onViewDebts,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.accountsCardViewDebts),
          ),
          if (!isCurrencyValid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "Moeda inválida",
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

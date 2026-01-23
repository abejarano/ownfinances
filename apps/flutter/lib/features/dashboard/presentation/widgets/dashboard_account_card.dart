import 'package:flutter/material.dart';
import 'package:ownfinances/core/presentation/components/money_text.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/core/utils/currency_utils.dart';
import 'package:ownfinances/core/utils/formatters.dart';
import 'package:ownfinances/features/dashboard/application/state/dashboard_state.dart';

class DashboardAccountCard extends StatelessWidget {
  final DashboardAccountSummary summary;
  final VoidCallback onTap;

  const DashboardAccountCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Styling based on state (Active vs Deactivated)
    final isActive = summary.account.isActive;

    // Dim functionality for inactive accounts, though logic filters them out usually ??
    // Assuming we show inactive if they have history??
    // PO didn't specify showing inactive.
    // Plan says "Deactivated: Dimmed visual".

    final bg = AppColors.surface1; // #111C2F
    final opacity = isActive ? 1.0 : 0.6;

    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.account.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (summary.account.type == 'credit_card')
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      "CARTÃO",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Text(
                    CurrencyUtils.formatCurrencyLabel(summary.account.currency),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (summary.account.type == 'credit_card' ||
                summary.linkedDebt != null) ...[
              // --- DEBT LAYOUT (Compact) ---
              // Line 1: Header Row (Label + Due Date)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Saldo a pagar",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (summary.linkedDebt?.dueDay != null)
                    Text(
                      "Vence dia ${summary.linkedDebt!.dueDay}",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),

              // Line 2: Big Money
              MoneyText(
                value:
                    (summary.linkedDebt?.amountDue ?? summary.totalBalance ?? 0)
                        .abs(),
                variant: MoneyTextVariant.l,
                color: AppColors.danger,
                symbol: summary.account.currency,
              ),

              const SizedBox(height: 8),

              // Line 3: Month Activity Grid (No Divider)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Col 1: Pagamentos (Green)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Pagamentos",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        MoneyText(
                          value: summary.income,
                          variant: MoneyTextVariant.s,
                          color: AppColors.success,
                          symbol: summary.account.currency,
                        ),
                      ],
                    ),
                  ),
                  // Col 2: Compras (Warning)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Compras",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        MoneyText(
                          value: summary.expense,
                          variant: MoneyTextVariant.s,
                          color: AppColors.warning,
                          symbol: summary.account.currency,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else if (summary.hasMovements) ...[
              // --- ASSET LAYOUT (Standard) ---
              _RowMetric(
                label: "Entradas",
                value: summary.income,
                color: AppColors.success,
                currency: summary.account.currency,
              ),
              const SizedBox(height: 4),
              _RowMetric(
                label: "Saídas",
                value: summary.expense,
                color: AppColors.warning,
                currency: summary.account.currency,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1, color: AppColors.borderSoft),
              ),
              // Balance Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Saldo do mês",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  MoneyText(
                    value: summary.balance,
                    variant: MoneyTextVariant.m,
                    color: summary.balance >= 0
                        ? AppColors.success
                        : AppColors.danger,
                    symbol: summary.account.currency,
                  ),
                ],
              ),
            ] else ...[
              // No Movements (Asset Only)
              const Expanded(
                child: Center(
                  child: Text(
                    "Sem movimentos este mês",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],

            const Spacer(),

            if (isActive)
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Ver transações",
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RowMetric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String currency;

  const _RowMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        Text(
          formatMoney(value, symbol: currency),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

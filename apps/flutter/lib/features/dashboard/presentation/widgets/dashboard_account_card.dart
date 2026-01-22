import 'package:flutter/material.dart';
import 'package:ownfinances/core/presentation/components/money_text.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
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
        padding: const EdgeInsets.all(16),
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
                    summary.account.currency,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            if (summary.hasMovements) ...[
              // Metrics
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

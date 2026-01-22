import 'package:flutter/material.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/features/dashboard/application/state/dashboard_state.dart';

class DashboardOtherCurrenciesCard extends StatelessWidget {
  final List<DashboardCurrencySummary> otherCurrencies;

  const DashboardOtherCurrenciesCard({
    super.key,
    required this.otherCurrencies,
  });

  @override
  Widget build(BuildContext context) {
    if (otherCurrencies.isEmpty) return const SizedBox.shrink();

    // Format: "Outras moedas (sem conversão)"
    // "USDT +18.000 • EUR +120"

    // We need to format the values appropriately.
    // Assuming simple string concatenation for MVP, but should respect formatting.
    // For now: CODE VALUE

    final content = otherCurrencies
        .map((c) {
          final sign = c.balance >= 0 ? "+" : "";
          return "${c.currency} $sign${c.balance.toStringAsFixed(2)}";
        })
        .join(" • ");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Outras moedas (sem conversão)",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

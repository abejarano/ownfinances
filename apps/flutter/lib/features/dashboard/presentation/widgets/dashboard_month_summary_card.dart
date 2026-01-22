import 'package:flutter/material.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/core/presentation/components/money_text.dart';
import 'package:ownfinances/features/dashboard/application/state/dashboard_state.dart';

class DashboardMonthSummaryCard extends StatelessWidget {
  final DashboardState state;
  final String periodLabel;
  final VoidCallback onTap;

  const DashboardMonthSummaryCard({
    super.key,
    required this.state,
    required this.periodLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Logic: If no movements in BRL
    if (!state.hasMainCurrencyMovements) {
      return Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(periodLabel: periodLabel),
                const SizedBox(height: 24),
                const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.textSecondary,
                        size: 32,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Sem movimentos em BRL neste mês.\nVeja suas contas abaixo.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    }

    final net = state.mainCurrencyNet;
    final isBlue = net >= 0;

    // Status Logic
    final statusText = isBlue ? "No azul" : "No vermelho";
    final statusIcon = isBlue
        ? Icons.check_circle
        : Icons.warning_amber_rounded;
    final statusColor = isBlue ? AppColors.success : AppColors.danger;
    final statusBg = isBlue ? AppColors.successSoft : AppColors.dangerSoft;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(periodLabel: periodLabel),
              const SizedBox(height: 12),

              // Status Chip
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Key Metrics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _Metric(
                      label: "Entradas",
                      value: state.mainCurrencyIncome,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Metric(
                      label: "Saídas",
                      value: state.mainCurrencyExpense,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Metric(
                      label: "Saldo",
                      value: state.mainCurrencyNet,
                      color: isBlue ? AppColors.success : AppColors.danger,
                      isBold: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String periodLabel;
  const _Header({required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Resumo do mês (BRL)",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              periodLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isBold;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(overflow: TextOverflow.ellipsis),
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: MoneyText(
            value: value,
            variant: isBold ? MoneyTextVariant.xl : MoneyTextVariant.m,
            color: color,
            // Assuming BRL main summary
          ),
        ),
      ],
    );
  }
}

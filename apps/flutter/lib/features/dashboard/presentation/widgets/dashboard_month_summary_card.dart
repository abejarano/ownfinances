import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import 'package:ownfinances/core/presentation/components/money_text.dart';
import 'package:ownfinances/features/reports/domain/entities/report_summary.dart';

class DashboardMonthSummaryCard extends StatelessWidget {
  final ReportSummary? summary;
  final String periodLabel;
  final VoidCallback onTap;

  const DashboardMonthSummaryCard({
    super.key,
    required this.summary,
    required this.periodLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final totals = summary!.totals;
    final netActual = totals.actualNet;
    final isBlue = netActual >= 0;

    // Status Logic
    final statusText = isBlue ? "No azul" : "No vermelho";
    final statusIcon = isBlue
        ? Icons.check_circle
        : Icons.warning_amber_rounded;
    final statusColor = isBlue ? AppColors.success : AppColors.danger;
    final statusBg = isBlue ? AppColors.successSoft : AppColors.dangerSoft;

    return Card(
      // Card defaults from AppTheme.darkCalm (Surface-1)
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Month & Chevron
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    periodLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
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
                      value: totals.actualIncome,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Metric(
                      label: "Saídas",
                      value: totals.actualExpense,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Metric(
                      label: "Saldo",
                      value: totals.actualNet,
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
          ),
        ),
      ],
    );
  }
}

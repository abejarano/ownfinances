import 'package:flutter/material.dart';
import 'package:ownfinances/core/utils/formatters.dart';
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
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final totals = summary!.totals;
    final netActual = totals.actualNet;
    final isBlue = netActual >= 0;

    // Status Text
    final statusText = isBlue
        ? "Você está no azul ✅"
        : "Você está no vermelho ⚠️";
    final statusColor = isBlue ? Colors.green.shade700 : Colors.red.shade700;
    final cardColor = isBlue ? Colors.green.shade50 : Colors.red.shade50;

    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isBlue ? Colors.green.shade100 : Colors.red.shade100,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Month & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    periodLabel,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade600),
                ],
              ),
              const SizedBox(height: 12),

              // Big Status Text
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 16),

              // Key Metrics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Metric(
                    label: "Entradas",
                    value: totals.actualIncome,
                    color: Colors.green,
                  ),
                  _Metric(
                    label: "Saídas",
                    value: totals.actualExpense,
                    color: Colors.red,
                  ),
                  _Metric(
                    label: "Saldo",
                    value: totals.actualNet,
                    color: isBlue ? Colors.green.shade800 : Colors.red.shade800,
                    isBold: true,
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          formatMoney(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

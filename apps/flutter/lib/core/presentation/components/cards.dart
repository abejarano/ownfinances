import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/presentation/components/money_text.dart";

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondary.withOpacity(0.15),
              child: Icon(icon, color: AppColors.secondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InlineSummaryCard extends StatelessWidget {
  final String title;
  final double planned;
  final double actual;
  final double remaining;

  const InlineSummaryCard({
    super.key,
    required this.title,
    required this.planned,
    required this.actual,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(label: "Planificado", value: planned),
          _SummaryRow(label: "Actual", value: actual),
          _SummaryRow(label: "Restante", value: remaining),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          MoneyText(
            value: value,
            variant: MoneyTextVariant.m,
            // Inline summaries are usually small, m is 18sp. Maybe too big?
            // Spec: "moneyM: 18sp".
            // Previous: w600 (default size).
            // Let's stick to moneyM as it's the standard.
            // Or maybe moneyS (not defined in strict list but logical)?
            // Strict list: XL, L, M.
            // If M is too big, I might need S.
            // Spec says: "moneyM (18sp)".
            // Let's use M. If it looks huge, we fix.
            // Actually, context: "Resumo do periodo".
            // Let's use M.
          ),
        ],
      ),
    );
  }
}

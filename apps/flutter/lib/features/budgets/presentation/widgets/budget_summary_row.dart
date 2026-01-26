import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";

class BudgetSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const BudgetSummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

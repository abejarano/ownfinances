import 'package:flutter/material.dart';
import 'package:ownfinances/core/theme/app_theme.dart';

class BudgetSummaryItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isBold;
  final bool? isExpense;
  final CrossAxisAlignment alignment;

  const BudgetSummaryItem({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    this.isBold = false,
    this.isExpense,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    if (isExpense != null) {
      icon = isExpense! ? Icons.arrow_downward : Icons.arrow_upward;
    }

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (icon != null) ...[
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isExpense! ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ] else ...[
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

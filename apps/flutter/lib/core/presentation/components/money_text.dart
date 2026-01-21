import 'package:flutter/material.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/core/utils/formatters.dart';

enum MoneyTextVariant {
  xl, // 24sp / w600 (Header Totals)
  l, // 22sp / w600 (Card Totals)
  m, // 18sp / w600 (List Amounts)
  s, // 16sp / w600 (Secondary stats)
}

class MoneyText extends StatelessWidget {
  final double value;
  final MoneyTextVariant variant;
  final Color? color;
  final bool? obscure; // For privacy mode if needed later

  const MoneyText({
    super.key,
    required this.value,
    this.variant = MoneyTextVariant.m,
    this.color,
    this.obscure,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Base style from theme + Manrope
    TextStyle style;

    switch (variant) {
      case MoneyTextVariant.xl:
        style = theme.textTheme.headlineMedium!.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2, // Tighter for large numbers
        );
        break;
      case MoneyTextVariant.l:
        style = theme.textTheme.headlineSmall!.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        );
        break;
      case MoneyTextVariant.m:
        style = theme.textTheme.titleMedium!.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        );
        break;
      case MoneyTextVariant.s:
        style = theme.textTheme.bodyMedium!.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        );
        break;
    }

    // Apply tabular figures and color
    style = style.copyWith(
      color: color ?? AppColors.textPrimary, // Default color if not provided
      fontFeatures: [const FontFeature.tabularFigures()],
    );

    return Text(formatMoney(value), style: style);
  }
}

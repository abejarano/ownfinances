import 'package:flutter/material.dart';
import 'package:ownfinances/core/theme/app_theme.dart';

class CategoryIcon extends StatelessWidget {
  final String? iconName;
  final String? categoryKind; // 'income', 'expense'
  final double size;
  final double iconSize;

  const CategoryIcon({
    super.key,
    required this.iconName,
    this.categoryKind,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _resolveIcon(iconName);
    final bgColor = _resolveBackgroundColor(categoryKind);
    final iconColor = _resolveIconColor(categoryKind);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor,
      child: Icon(iconData, size: iconSize, color: iconColor),
    );
  }

  Color _resolveBackgroundColor(String? kind) {
    if (kind == 'income') return AppColors.successSoft;
    if (kind == 'expense') return AppColors.warningSoft;
    return AppColors.surface2; // Default/Neutral
  }

  Color _resolveIconColor(String? kind) {
    if (kind == 'income') return AppColors.success;
    if (kind == 'expense') return AppColors.warning;
    return AppColors.textSecondary; // Default/Neutral
  }

  IconData _resolveIcon(String? iconName) {
    if (iconName == null) return Icons.category;
    const map = {
      "salary": Icons.attach_money,
      "restaurant": Icons.restaurant,
      "home": Icons.home,
      "transport": Icons.directions_car,
      "leisure": Icons.movie,
      "health": Icons.medical_services,
      "shopping": Icons.shopping_bag,
      "bills": Icons.receipt_long,
      "entertainment": Icons.sports_esports,
      "education": Icons.school,
      "gym": Icons.fitness_center,
      "travel": Icons.flight,
      "gift": Icons.card_giftcard,
      "investment": Icons.trending_up,
      "family": Icons.family_restroom,
    };
    return map[iconName] ?? Icons.category;
  }
}

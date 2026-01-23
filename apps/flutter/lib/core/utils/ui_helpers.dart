import 'package:flutter/material.dart';

class IconOption {
  final String id;
  final String label;
  final IconData icon;

  const IconOption({required this.id, required this.label, required this.icon});
}

const List<IconOption> kIconOptions = [
  IconOption(id: "restaurant", label: "Comida", icon: Icons.restaurant),
  IconOption(id: "shopping", label: "Compras", icon: Icons.shopping_bag),
  IconOption(id: "home", label: "Casa", icon: Icons.home),
  IconOption(id: "transport", label: "Transporte", icon: Icons.directions_car),
  IconOption(id: "health", label: "Saúde", icon: Icons.local_hospital),
  IconOption(id: "education", label: "Educação", icon: Icons.school),
  IconOption(id: "salary", label: "Salário", icon: Icons.payments),
  IconOption(id: "gift", label: "Presente", icon: Icons.card_giftcard),
  IconOption(id: "travel", label: "Viagem", icon: Icons.flight),
  IconOption(id: "leisure", label: "Lazer", icon: Icons.movie),
  IconOption(
    id: "wallet",
    label: "Carteira",
    icon: Icons.account_balance_wallet,
  ),
  IconOption(id: "goal", label: "Meta", icon: Icons.flag),
];

Color? parseColor(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final cleaned = value.trim().replaceAll("#", "");
  final parsed = int.tryParse(
    cleaned.length == 6 ? "FF$cleaned" : cleaned,
    radix: 16,
  );
  if (parsed == null) return null;
  return Color(parsed);
}

IconData? getIconFor(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  for (final option in kIconOptions) {
    if (option.id == value) return option.icon;
  }
  return null;
}

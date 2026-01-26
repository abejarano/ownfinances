import "package:flutter/material.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class DefaultCategorySeed {
  final String id;
  String name;
  final String kind;
  final String? icon;
  final String color;
  bool selected;

  DefaultCategorySeed({
    required this.id,
    required this.name,
    required this.kind,
    this.icon,
    required this.color,
    this.selected = true,
  });
}

List<DefaultCategorySeed> buildDefaultCategorySeeds(
  AppLocalizations l10n, {
  Map<String, bool>? selectionMap,
}) {
  final rawList = [
    DefaultCategorySeed(
      id: "housing",
      name: l10n.catHousing,
      icon: "home",
      kind: "expense",
      color: "#DB2777",
    ),
    DefaultCategorySeed(
      id: "utilities",
      name: l10n.catUtilities,
      icon: "bolt",
      kind: "expense",
      color: "#F59E0B",
    ),
    DefaultCategorySeed(
      id: "internet",
      name: l10n.catInternet,
      icon: "wifi",
      kind: "expense",
      color: "#3B82F6",
    ),
    DefaultCategorySeed(
      id: "groceries",
      name: l10n.catGroceries,
      icon: "shopping_cart",
      kind: "expense",
      color: "#EA580C",
    ),
    DefaultCategorySeed(
      id: "restaurants",
      name: l10n.catRestaurants,
      icon: "restaurant",
      kind: "expense",
      color: "#EF4444",
    ),
    DefaultCategorySeed(
      id: "transport",
      name: l10n.catTransport,
      icon: "directions_car",
      kind: "expense",
      color: "#64748B",
    ),
    DefaultCategorySeed(
      id: "car_maint",
      name: l10n.catCarMaintenance,
      icon: "build",
      kind: "expense",
      color: "#475569",
    ),
    DefaultCategorySeed(
      id: "health",
      name: l10n.catHealth,
      icon: "favorite",
      kind: "expense",
      color: "#06B6D4",
    ),
    DefaultCategorySeed(
      id: "education",
      name: l10n.catEducation,
      icon: "school",
      kind: "expense",
      color: "#7C3AED",
    ),
    DefaultCategorySeed(
      id: "debts",
      name: l10n.catDebts,
      icon: "attach_money",
      kind: "expense",
      color: "#E11D48",
    ),
    DefaultCategorySeed(
      id: "subscriptions",
      name: l10n.catSubscriptions,
      icon: "subscriptions",
      kind: "expense",
      color: "#8B5CF6",
    ),
    DefaultCategorySeed(
      id: "personal",
      name: l10n.catPersonal,
      icon: "face",
      kind: "expense",
      color: "#EC4899",
    ),
    DefaultCategorySeed(
      id: "clothing",
      name: l10n.catClothing,
      icon: "checkroom",
      kind: "expense",
      color: "#14B8A6",
    ),
    DefaultCategorySeed(
      id: "work",
      name: l10n.catWork,
      icon: "work",
      kind: "expense",
      color: "#374151",
    ),
    DefaultCategorySeed(
      id: "taxes",
      name: l10n.catTaxes,
      icon: "account_balance",
      kind: "expense",
      color: "#94A3B8",
    ),
  ];

  if (selectionMap != null) {
    for (final item in rawList) {
      if (selectionMap.containsKey(item.id)) {
        item.selected = selectionMap[item.id]!;
      }
    }
  }

  return rawList;
}

IconData defaultCategoryIcon(String? name) {
  switch (name) {
    case "home":
      return Icons.home;
    case "bolt":
      return Icons.bolt;
    case "wifi":
      return Icons.wifi;
    case "shopping_cart":
      return Icons.shopping_cart;
    case "restaurant":
      return Icons.restaurant;
    case "directions_car":
      return Icons.directions_car;
    case "local_gas_station":
      return Icons.local_gas_station;
    case "build":
      return Icons.build;
    case "favorite":
      return Icons.favorite;
    case "local_pharmacy":
      return Icons.local_pharmacy;
    case "school":
      return Icons.school;
    case "credit_card":
      return Icons.credit_card;
    case "attach_money":
      return Icons.attach_money;
    case "percent":
      return Icons.percent;
    case "subscriptions":
      return Icons.subscriptions;
    case "face":
      return Icons.face;
    case "checkroom":
      return Icons.checkroom;
    case "work":
      return Icons.work;
    case "account_balance":
      return Icons.account_balance;
    default:
      return Icons.category;
  }
}

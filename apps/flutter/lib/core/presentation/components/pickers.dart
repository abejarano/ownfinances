import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/currency_utils.dart";
import "package:ownfinances/l10n/app_localizations.dart";

import "month_picker_dialog.dart";

typedef AsyncDateRangeCallback = void Function(int year, int month);

Future<void> pickMonth(
  BuildContext context,
  AsyncDateRangeCallback onValue, {
  DateTime? initialDate,
}) async {
  final selected = await showDialog<DateTime>(
    context: context,
    builder: (context) => MonthPickerDialog(
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    ),
  );
  if (selected == null) return;

  if (!context.mounted) return;

  onValue(selected.year, selected.month);
}

class PickerItem {
  final String id;
  final String label;

  const PickerItem({required this.id, required this.label});
}

class CategoryPicker extends StatelessWidget {
  final String label;
  final List<PickerItem> items;
  final String? value;
  final ValueChanged<PickerItem> onSelected;

  const CategoryPicker({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerField(
      label: label,
      value: value,
      items: items,
      onSelected: onSelected,
    );
  }
}

class AccountPicker extends StatelessWidget {
  final String label;
  final List<PickerItem> items;
  final String? value;
  final ValueChanged<PickerItem> onSelected;

  const AccountPicker({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _PickerField(
      label: label,
      value: value,
      items: items,
      onSelected: onSelected,
    );
  }
}

class CurrencyPickerField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onSelected;
  final bool allowCustom;

  const CurrencyPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onSelected,
    this.allowCustom = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            Expanded(
              child: Text(_displayValue(l10n), overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.expand_more, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      ...CurrencyUtils.commonCurrencies,
      if (allowCustom) "OTHER",
    ];
    final isCupertino =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isCupertino) {
      final selected = await showCupertinoModalPopup<String>(
        context: context,
        builder: (context) {
          return CupertinoActionSheet(
            title: Text(label),
            actions: [
              for (final code in options)
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context, code),
                  child: Text(
                    code == "OTHER"
                        ? l10n.currencyOther
                        : CurrencyUtils.formatCurrencyLabel(code),
                  ),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
          );
        },
      );
      onSelected(selected);
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final code in options)
                ListTile(
                  title: Text(
                    code == "OTHER"
                        ? l10n.currencyOther
                        : CurrencyUtils.formatCurrencyLabel(code),
                  ),
                  trailing: value == code
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, code),
                ),
            ],
          ),
        );
      },
    );
    onSelected(selected);
  }

  String _displayValue(AppLocalizations l10n) {
    if (value == null) return "";
    if (value == "OTHER") return l10n.currencyOther;
    return _shortCurrencyLabel(value!, l10n);
  }

  String _shortCurrencyLabel(String code, AppLocalizations l10n) {
    switch (code) {
      case "BRL":
        return "R\$ · BRL";
      case "USD":
        return "\$ · USD";
      case "EUR":
        return "€ · EUR";
      case "GBP":
        return "£ · GBP";
      case "COP":
        return "COP";
      case "ARS":
        return "ARS";
      case "PYG":
        return "PYG";
      case "UYU":
        return "UYU";
      case "VES":
        return "VES";
      case "USDT":
        return "USDT";
      default:
        return code;
    }
  }
}

class ColorPicker extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onSelected;

  const ColorPicker({
    super.key,
    required this.label,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final display = value ?? "Sem cor";
    return InkWell(
      onTap: () async {
        final selected = await showModalBottomSheet<String?>(
          context: context,
          showDragHandle: true,
          builder: (context) => _ColorPickerSheet(selected: value),
        );
        if (selected != null) {
          onSelected(selected.isEmpty ? null : selected);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            _ColorDot(color: _parseHexColor(value)),
            const SizedBox(width: AppSpacing.sm),
            Text(display),
          ],
        ),
      ),
    );
  }
}

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
  IconOption(id: "health", label: "Saude", icon: Icons.local_hospital),
  IconOption(id: "education", label: "Educacao", icon: Icons.school),
  IconOption(id: "salary", label: "Salario", icon: Icons.payments),
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

class IconPicker extends StatelessWidget {
  final String label;
  final String? value;
  final List<IconOption> options;
  final ValueChanged<String?> onSelected;

  const IconPicker({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.where((item) => item.id == value).toList();
    final display = selected.isEmpty ? "Sem icone" : selected.first.label;
    final icon = selected.isEmpty ? Icons.help_outline : selected.first.icon;
    return InkWell(
      onTap: () async {
        final selectedId = await showModalBottomSheet<String?>(
          context: context,
          showDragHandle: true,
          builder: (context) =>
              _IconPickerSheet(items: options, selected: value),
        );
        if (selectedId != null) {
          onSelected(selectedId.isEmpty ? null : selectedId);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(display),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final List<PickerItem> items;
  final String? value;
  final ValueChanged<PickerItem> onSelected;

  const _PickerField({
    required this.label,
    required this.items,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await showModalBottomSheet<PickerItem>(
          context: context,
          showDragHandle: true,
          builder: (context) =>
              _PickerSheet(title: label, items: items, selected: value),
        );
        if (selected != null) {
          onSelected(selected);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(_labelForValue(items, value) ?? "Selecionar"),
      ),
    );
  }
}

String? _labelForValue(List<PickerItem> items, String? value) {
  if (value == null) return null;
  for (final item in items) {
    if (item.id == value) return item.label;
  }
  return null;
}

class _ColorPickerSheet extends StatelessWidget {
  final String? selected;

  const _ColorPickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Color", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ColorChoice(
                  label: "Sem cor",
                  selected: selected == null,
                  color: null,
                  onTap: () => Navigator.of(context).pop(""),
                ),
                ...kColorOptions.map(
                  (hex) => _ColorChoice(
                    label: hex,
                    selected: hex == selected,
                    color: _parseHexColor(hex),
                    onTap: () => Navigator.of(context).pop(hex),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _ColorChoice({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.secondary : Colors.black12;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ColorDot(color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color? color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.transparent,
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}

class _IconPickerSheet extends StatefulWidget {
  final List<IconOption> items;
  final String? selected;

  const _IconPickerSheet({required this.items, required this.selected});

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((item) => item.label.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Icone", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Buscar",
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length + 1,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: const Icon(Icons.clear),
                      title: const Text("Sem icone"),
                      onTap: () => Navigator.of(context).pop(""),
                    );
                  }
                  final item = filtered[index - 1];
                  return ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    trailing: item.id == widget.selected
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(context).pop(item.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> kColorOptions = [
  "#22C55E",
  "#16A34A",
  "#0EA5E9",
  "#2563EB",
  "#7C3AED",
  "#DB2777",
  "#F97316",
  "#EAB308",
  "#F59E0B",
  "#10B981",
  "#06B6D4",
  "#64748B",
];

Color? _parseHexColor(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final cleaned = value.trim().replaceAll("#", "");
  final parsed = int.tryParse(
    cleaned.length == 6 ? "FF$cleaned" : cleaned,
    radix: 16,
  );
  if (parsed == null) return null;
  return Color(parsed);
}

class _PickerSheet extends StatefulWidget {
  final String title;
  final List<PickerItem> items;
  final String? selected;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.selected,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((item) => item.label.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Buscar",
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return ListTile(
                    title: Text(item.label),
                    trailing: item.id == widget.selected
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(context).pop(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

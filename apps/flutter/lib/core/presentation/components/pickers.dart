import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";

class CategoryPicker extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String> onSelected;

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
  final List<String> items;
  final String? value;
  final ValueChanged<String> onSelected;

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

class _PickerField extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String> onSelected;

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
        final selected = await showModalBottomSheet<String>(
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
        child: Text(value ?? "Seleccionar"),
      ),
    );
  }
}

class _PickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
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
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
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
                    title: Text(item),
                    trailing: item == widget.selected
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

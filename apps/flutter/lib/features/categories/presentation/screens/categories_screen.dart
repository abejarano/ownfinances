import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import 'package:ownfinances/l10n/app_localizations.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CategoriesController>();
    final state = context.watch<CategoriesController>().state;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.drawerCategories),

        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => context.go("/transactions"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.categoriesActive,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.load,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator()),
            if (!state.isLoading)
              Expanded(
                child: ListView.separated(
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final color = _parseColor(item.color);
                    final iconData = _iconFor(item.icon);
                    final iconLabel = item.name.trim().isNotEmpty
                        ? item.name.trim()[0].toUpperCase()
                        : "?";
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color ?? Colors.black12,
                        child: iconData != null
                            ? Icon(
                                iconData,
                                color: color == null
                                    ? Colors.black87
                                    : Colors.white,
                              )
                            : Text(
                                iconLabel,
                                style: TextStyle(
                                  color: color == null
                                      ? Colors.black87
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      title: Text(item.name),
                      subtitle: Text(
                        item.kind == "income"
                            ? l10n.transactionTypeIncome
                            : l10n.transactionTypeExpense,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _openForm(context, controller, item: item),
                      ),
                      onLongPress: () async {
                        final confirmed = await _confirmDelete(
                          context,
                          title: l10n.categoriesDeleteTitle,
                          description: l10n.categoriesDeleteDesc,
                        );
                        if (!confirmed || !context.mounted) return;

                        final error = await controller.remove(item.id);
                        if (!context.mounted) return;
                        if (error != null) {
                          showStandardSnackbar(context, error);
                          return;
                        }
                        await context.read<ReportsController>().load();
                        if (context.mounted) {
                          showStandardSnackbar(context, l10n.categoriesDeleted);
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, controller),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context, {
    required String title,
    required String description,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.commonDelete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openForm(
    BuildContext context,
    CategoriesController controller, {
    Category? item,
  }) async {
    final nameController = TextEditingController(text: item?.name ?? "");
    String kind = item?.kind ?? "expense";
    String? parentId = item?.parentId;
    String? color = item?.color;
    String? icon = item?.icon;
    bool isActive = item?.isActive ?? true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final categories = controller.state.items
            .where((category) => category.id != item?.id)
            .map(
              (category) => PickerItem(id: category.id, label: category.name),
            )
            .toList();
        final parentItems = [
          PickerItem(
            id: "",
            label: AppLocalizations.of(context)!.categoriesNoParent,
          ),
          ...categories,
        ];
        return StatefulBuilder(
          builder: (context, setModalState) {
            final previewColor = _parseColor(color);
            final previewIcon = _iconFor(icon);
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item == null
                        ? AppLocalizations.of(context)!.categoriesNew
                        : AppLocalizations.of(context)!.categoriesEdit,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: previewColor ?? Colors.black12,
                        child: previewIcon != null
                            ? Icon(
                                previewIcon,
                                color: previewColor == null
                                    ? Colors.black87
                                    : Colors.white,
                              )
                            : Text(
                                nameController.text.trim().isNotEmpty
                                    ? nameController.text
                                          .trim()
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : "?",
                                style: TextStyle(
                                  color: previewColor == null
                                      ? Colors.black87
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        nameController.text.trim().isEmpty
                            ? AppLocalizations.of(context)!.commonPreview
                            : nameController.text.trim(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.commonName,
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CategoryPicker(
                    label: AppLocalizations.of(context)!.categoriesParent,
                    items: parentItems,
                    value: parentId ?? "",
                    onSelected: (item) {
                      setModalState(() {
                        parentId = item.id.isEmpty ? null : item.id;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: kind,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.accountTypeLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: "expense",
                        child: Text(
                          AppLocalizations.of(context)!.transactionTypeExpense,
                        ),
                      ),
                      DropdownMenuItem(
                        value: "income",
                        child: Text(
                          AppLocalizations.of(context)!.transactionTypeIncome,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => kind = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ColorPicker(
                    label: AppLocalizations.of(context)!.categoriesColor,
                    value: color,
                    onSelected: (value) {
                      setModalState(() => color = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  IconPicker(
                    label: AppLocalizations.of(context)!.categoriesIcon,
                    value: icon,
                    options: kIconOptions,
                    onSelected: (value) {
                      setModalState(() => icon = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context)!.commonActive),
                    value: isActive,
                    onChanged: (value) => setModalState(() => isActive = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: AppLocalizations.of(context)!.commonSave,
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      if (context.mounted) {
        showStandardSnackbar(
          context,
          AppLocalizations.of(context)!.commonNameRequired,
        );
      }
      return;
    }
    String? error;
    if (item == null) {
      error = await controller.create(
        name: name,
        kind: kind,
        parentId: parentId,
        color: color,
        icon: icon,
        isActive: isActive,
      );
    } else {
      error = await controller.update(
        id: item.id,
        name: name,
        kind: kind,
        parentId: parentId,
        color: color,
        icon: icon,
        isActive: isActive,
      );
    }
    if (error != null && context.mounted) {
      showStandardSnackbar(context, error);
    }
  }

  Color? _parseColor(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim().replaceAll("#", "");
    final parsed = int.tryParse(
      cleaned.length == 6 ? "FF$cleaned" : cleaned,
      radix: 16,
    );
    if (parsed == null) return null;
    return Color(parsed);
  }

  IconData? _iconFor(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    for (final option in kIconOptions) {
      if (option.id == value) return option.icon;
    }
    return null;
  }
}

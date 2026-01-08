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

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CategoriesController>();
    final state = context.watch<CategoriesController>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Categorias"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go("/dashboard"),
        ),
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
                    "Categorias ativas",
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
                      subtitle: Text(item.kind == "income" ? "Entrou" : "Saiu"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _openForm(context, controller, item: item),
                      ),
                      onLongPress: () async {
                        final confirmed = await _confirmDelete(
                          context,
                          title: "Excluir categoria?",
                          description:
                              "Isso vai excluir a categoria e todas as transacoes vinculadas. Nao da pra desfazer.",
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
                          showStandardSnackbar(context, "Categoria excluida");
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
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
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
          const PickerItem(id: "", label: "Sem pai"),
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
                    item == null ? "Nova categoria" : "Editar categoria",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                            ? "Preview"
                            : nameController.text.trim(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Nome"),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CategoryPicker(
                    label: "Categoria pai",
                    items: parentItems,
                    value: parentId ?? "",
                    onSelected: (item) {
                      setModalState(() {
                        parentId = item.id.isEmpty ? null : item.id;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: kind,
                    decoration: const InputDecoration(labelText: "Tipo"),
                    items: const [
                      DropdownMenuItem(value: "expense", child: Text("Saiu")),
                      DropdownMenuItem(value: "income", child: Text("Entrou")),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => kind = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ColorPicker(
                    label: "Cor",
                    value: color,
                    onSelected: (value) {
                      setModalState(() => color = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  IconPicker(
                    label: "Icone",
                    value: icon,
                    options: kIconOptions,
                    onSelected: (value) {
                      setModalState(() => icon = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Ativa"),
                    value: isActive,
                    onChanged: (value) => setModalState(() => isActive = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: "Salvar",
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
        showStandardSnackbar(context, "Nome obrigatorio");
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

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AccountsController>();
    final state = context.watch<AccountsController>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cuentas"),
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
                    "Cuentas activas",
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
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text("${item.type} • ${item.currency}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _openForm(context, controller, item: item),
                      ),
                      onLongPress: () async {
                        final error = await controller.remove(item.id);
                        if (error != null && context.mounted) {
                          showStandardSnackbar(context, error);
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

  Future<void> _openForm(
    BuildContext context,
    AccountsController controller, {
    Account? item,
  }) async {
    final nameController = TextEditingController(text: item?.name ?? "");
    final currencyController = TextEditingController(
      text: item?.currency ?? "BRL",
    );
    String type = item?.type ?? "cash";
    bool isActive = item?.isActive ?? true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item == null ? "Nueva cuenta" : "Editar cuenta",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nome"),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: "Tipo"),
                items: const [
                  DropdownMenuItem(value: "cash", child: Text("Efectivo")),
                  DropdownMenuItem(value: "bank", child: Text("Banco")),
                  DropdownMenuItem(value: "wallet", child: Text("Billetera")),
                  DropdownMenuItem(value: "broker", child: Text("Inversiones")),
                  DropdownMenuItem(
                    value: "credit_card",
                    child: Text("Tarjeta"),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) type = value;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(labelText: "Moeda"),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Ativa"),
                value: isActive,
                onChanged: (value) => isActive = value,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: "Guardar",
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );

    if (result != true) return;
    final name = nameController.text.trim();
    final currency = currencyController.text.trim();
    if (name.isEmpty) {
      if (context.mounted) {
        showStandardSnackbar(context, "Nombre requerido");
      }
      return;
    }
    String? error;
    if (item == null) {
      error = await controller.create(
        name: name,
        type: type,
        currency: currency.isEmpty ? "BRL" : currency,
        isActive: isActive,
      );
    } else {
      error = await controller.update(
        id: item.id,
        name: name,
        type: type,
        currency: currency.isEmpty ? "BRL" : currency,
        isActive: isActive,
      );
    }
    if (error != null && context.mounted) {
      showStandardSnackbar(context, error);
    }
  }
}

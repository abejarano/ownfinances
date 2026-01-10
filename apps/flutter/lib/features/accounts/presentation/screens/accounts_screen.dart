import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AccountsController>();
    final state = context.watch<AccountsController>().state;
    final reportsState = context.watch<ReportsController>().state;
    final balanceMap = {
      for (final item in reportsState.balances?.balances ?? [])
        item.accountId: item.balance,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contas"),
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
                    "Contas ativas",
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
                    final balance = balanceMap[item.id];
                    final balanceLabel = balance == null
                        ? "Saldo: —"
                        : "Saldo: ${formatMoney(balance)}";
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        "${item.type} • ${item.currency}\n$balanceLabel",
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _openForm(context, controller, item: item),
                      ),
                      onLongPress: () async {
                        final confirmed = await _confirmDelete(
                          context,
                          title: "Excluir conta?",
                          description:
                              "Isso vai excluir a conta e todas as transacoes vinculadas. Nao da pra desfazer.",
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
                          showStandardSnackbar(context, "Conta excluida");
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
    AccountsController controller, {
    Account? item,
  }) async {
    final nameController = TextEditingController(text: item?.name ?? "");
    final currencyController = TextEditingController(
      text: item?.currency ?? "BRL",
    );
    String type = item?.type ?? "cash";
    String? bankType = item?.bankType;
    bool isActive = item?.isActive ?? true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    item == null ? "Nova conta" : "Editar conta",
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
                      DropdownMenuItem(value: "cash", child: Text("Dinheiro")),
                      DropdownMenuItem(value: "bank", child: Text("Banco")),
                      DropdownMenuItem(
                        value: "wallet",
                        child: Text("Carteira"),
                      ),
                      DropdownMenuItem(
                        value: "broker",
                        child: Text("Investimentos"),
                      ),
                      DropdownMenuItem(
                        value: "credit_card",
                        child: Text("Cartao"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          type = value;
                          if (type != "bank") bankType = null;
                        });
                      }
                    },
                  ),
                  if (type == "bank") ...[
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: bankType,
                      decoration: const InputDecoration(labelText: "Banco"),
                      items: const [
                        DropdownMenuItem(
                          value: "nubank",
                          child: Text("Nubank"),
                        ),
                        DropdownMenuItem(value: "itau", child: Text("Itaú")),
                        DropdownMenuItem(
                          value: "bradesco",
                          child: Text("Bradesco"),
                        ),
                        DropdownMenuItem(value: "caixa", child: Text("Caixa")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          bankType = value;
                        });
                      },
                    ),
                  ],
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
                    onChanged: (value) => setState(() => isActive = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: "Salvar",
                    onPressed: () => Navigator.of(context).pop(true),
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
    final currency = currencyController.text.trim();
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
        type: type,
        currency: currency.isEmpty ? "BRL" : currency,
        isActive: isActive,
        bankType: type == "bank" ? bankType : null,
      );
    } else {
      error = await controller.update(
        id: item.id,
        name: name,
        type: type,
        currency: currency.isEmpty ? "BRL" : currency,
        isActive: isActive,
        bankType: type == "bank" ? bankType : null,
      );
    }
    if (error != null && context.mounted) {
      showStandardSnackbar(context, error);
    }
  }
}

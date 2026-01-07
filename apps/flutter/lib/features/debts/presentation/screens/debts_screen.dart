import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/debts/application/controllers/debts_controller.dart";
import "package:ownfinances/features/debts/domain/entities/debt.dart";

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DebtsController>();
    final state = context.watch<DebtsController>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dividas"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go("/dashboard"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Passivos ativos",
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
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final summary = state.summaries[item.id];
                    return _DebtCard(
                      debt: item,
                      balance: summary?.balanceComputed ?? 0,
                      nextDueDate: summary?.nextDueDate,
                      onCharge: () => _openDebtTransactionForm(
                        context,
                        item,
                        "charge",
                      ),
                      onPayment: () => _openDebtTransactionForm(
                        context,
                        item,
                        "payment",
                      ),
                      onEdit: () => _openDebtForm(
                        context,
                        controller,
                        item: item,
                      ),
                      onDelete: () async {
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
        onPressed: () => _openDebtForm(context, controller),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openDebtForm(
    BuildContext context,
    DebtsController controller, {
    Debt? item,
  }) async {
    final nameController = TextEditingController(text: item?.name ?? "");
    final currencyController = TextEditingController(
      text: item?.currency ?? "BRL",
    );
    final dueDayController = TextEditingController(
      text: item?.dueDay?.toString() ?? "",
    );
    final minimumPaymentController = TextEditingController(
      text: item?.minimumPayment != null
          ? formatMoney(item!.minimumPayment!)
          : "",
    );
    final interestController = TextEditingController(
      text: item?.interestRateAnnual?.toString() ?? "",
    );
    String type = item?.type ?? "credit_card";
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
                item == null ? "Nova divida" : "Editar divida",
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
                  DropdownMenuItem(
                    value: "credit_card",
                    child: Text("Cartao de credito"),
                  ),
                  DropdownMenuItem(value: "loan", child: Text("Emprestimo")),
                  DropdownMenuItem(value: "other", child: Text("Outro")),
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
              TextField(
                controller: dueDayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Dia de vencimento",
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              MoneyInput(
                label: "Minimo a pagar",
                controller: minimumPaymentController,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: interestController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Taxa anual (%)",
                ),
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
                label: "Salvar",
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
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

    final dueDay = int.tryParse(dueDayController.text.trim());
    final minimumPayment = parseMoney(minimumPaymentController.text.trim());
    final interest = double.tryParse(interestController.text.trim());

    String? error;
    if (item == null) {
      error = await controller.create(
        name: name,
        type: type,
        currency: currencyController.text.trim().isEmpty
            ? "BRL"
            : currencyController.text.trim(),
        dueDay: dueDay,
        minimumPayment: minimumPayment > 0 ? minimumPayment : null,
        interestRateAnnual: interest,
        isActive: isActive,
      );
    } else {
      error = await controller.update(
        id: item.id,
        name: name,
        type: type,
        currency: currencyController.text.trim().isEmpty
            ? "BRL"
            : currencyController.text.trim(),
        dueDay: dueDay,
        minimumPayment: minimumPayment > 0 ? minimumPayment : null,
        interestRateAnnual: interest,
        isActive: isActive,
      );
    }

    if (error != null && context.mounted) {
      showStandardSnackbar(context, error);
    }
  }

  Future<void> _openDebtTransactionForm(
    BuildContext context,
    Debt debt,
    String type,
  ) async {
    final controller = context.read<DebtsController>();
    final lastAccountId = controller.state.lastAccountId;

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime date = DateTime.now();
    String? accountId = lastAccountId;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final accountsState = context.watch<AccountsController>().state;
            final accountItems = accountsState.items
                .map((acc) => PickerItem(id: acc.id, label: acc.name))
                .toList();
            if (accountId == null && accountItems.isNotEmpty) {
              accountId = accountItems.first.id;
            }
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
                    type == "charge"
                        ? "Registrar compra"
                        : "Registrar pagamento",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MoneyInput(label: "Valor", controller: amountController),
                  const SizedBox(height: AppSpacing.sm),
                  if (accountItems.isEmpty)
                    const Text("Voce nao tem contas ativas.")
                  else
                    AccountPicker(
                      label: "Conta",
                      items: accountItems,
                      value: accountId,
                      onSelected: (item) =>
                          setState(() => accountId = item.id),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Fecha"),
                    subtitle: Text(formatDate(date)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) {
                        setState(() => date = selected);
                      }
                    },
                  ),
                  TextField(
                    controller: noteController,
                    decoration:
                        const InputDecoration(labelText: "Nota (opcional)"),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: "Salvar",
                    onPressed: accountItems.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true) return;

    final amount = parseMoney(amountController.text.trim());
    if (amount <= 0) {
      if (context.mounted) {
        showStandardSnackbar(context, "O valor deve ser maior que 0");
      }
      return;
    }

    final error = await controller.createDebtTransaction(
      debtId: debt.id,
      date: date,
      type: type,
      amount: amount,
      accountId: accountId,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
    );

    if (error != null && context.mounted) {
      showStandardSnackbar(context, error);
    }
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final double balance;
  final DateTime? nextDueDate;
  final VoidCallback onCharge;
  final VoidCallback onPayment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.balance,
    required this.nextDueDate,
    required this.onCharge,
    required this.onPayment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dueLabel = nextDueDate == null
        ? "Sem vencimento"
        : "Vence ${formatDate(nextDueDate!)}";
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    debt.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatMoney(balance),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "$dueLabel • ${debt.currency}",
              style: const TextStyle(color: AppColors.muted),
            ),
            if (debt.minimumPayment != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Minimo ${formatMoney(debt.minimumPayment!)}",
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: "Registrar compra",
                    onPressed: onCharge,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SecondaryButton(
                    label: "Registrar pagamento",
                    onPressed: onPayment,
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

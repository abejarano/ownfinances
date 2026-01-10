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
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
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
                    final amountDue = summary?.amountDue ?? 0;
                    final creditBalance = summary?.creditBalance ?? 0;
                    final paymentsThisMonth = summary?.paymentsThisMonth ?? 0;

                    return _DebtCard(
                      debt: item,
                      // We pass amountDue as the primary "balance" to show
                      amountDue: amountDue,
                      creditBalance: creditBalance,
                      paymentsThisMonth: paymentsThisMonth,
                      nextDueDate: summary?.nextDueDate,
                      onCharge: () =>
                          _openDebtTransactionForm(context, item, "charge"),
                      onPayment: () async {
                        if (amountDue == 0) {
                          // Confirmation dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Aviso"),
                              content: const Text(
                                "Você está em dia — não há saldo a pagar neste cartão.\n"
                                "Quer registrar este pagamento mesmo assim?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancelar"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Registrar mesmo assim"),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                        }

                        if (item.type == "credit_card" &&
                            item.linkedAccountId == null) {
                          final shouldLink = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Vincular cartão"),
                              content: const Text(
                                "Para registrar pagamentos, este cartão precisa estar ligado a uma conta do tipo Cartão.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancelar"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Vincular agora"),
                                ),
                              ],
                            ),
                          );

                          if (shouldLink == true && context.mounted) {
                            await _openDebtForm(
                              context,
                              controller,
                              item: item,
                            );
                            // We don't auto-proceed to payment because we'd need to re-fetch the item.
                            // The user can tap payment again now that it's linked.
                          }
                          return;
                        }

                        _openDebtTransactionForm(context, item, "payment");
                      },
                      onEdit: () =>
                          _openDebtForm(context, controller, item: item),
                      onDelete: () async {
                        final error = await controller.remove(item.id);
                        if (error != null && context.mounted) {
                          showStandardSnackbar(context, error);
                        }
                      },
                      onHistory: () =>
                          _openHistoryDialog(context, controller, item.id),
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

    // Initialize with existing link
    String? linkedAccountId = item?.linkedAccountId;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        // Read accounts state
        final accountsState = context.watch<AccountsController>().state;
        // Filter for credit cards
        final creditCardAccounts = accountsState.items
            .where((a) => a.type == "credit_card")
            .map((a) => PickerItem(id: a.id, label: a.name))
            .toList();

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
                      DropdownMenuItem(
                        value: "loan",
                        child: Text("Emprestimo"),
                      ),
                      DropdownMenuItem(value: "other", child: Text("Outro")),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => type = value);
                      }
                    },
                  ),
                  if (type == "credit_card") ...[
                    const SizedBox(height: AppSpacing.sm),
                    if (creditCardAccounts.isEmpty)
                      const Text(
                        "Voce nao tem contas do tipo 'Cartao de Credito' para vincular. Crie uma conta primeiro.",
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      )
                    else
                      AccountPicker(
                        label: "Conta vinculada (para pagamentos)",
                        items: creditCardAccounts,
                        value: linkedAccountId,
                        onSelected: (item) =>
                            setState(() => linkedAccountId = item.id),
                      ),
                  ],
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
        linkedAccountId: linkedAccountId,
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
        linkedAccountId: linkedAccountId,
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
    String? categoryId;

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
            final categoriesState = context.watch<CategoriesController>().state;
            final categoryItems = categoriesState.items
                .where((cat) => cat.kind == "expense")
                .map((cat) => PickerItem(id: cat.id, label: cat.name))
                .toList();
            if (categoryId == null &&
                categoryItems.isNotEmpty &&
                (type == "charge" ||
                    (type == "payment" && debt.type != "credit_card"))) {
              categoryId = categoryItems.first.id;
            }
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
                    type == "charge"
                        ? "Registrar compra"
                        : "Registrar pagamento",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MoneyInput(label: "Valor", controller: amountController),
                  const SizedBox(height: AppSpacing.sm),
                  if (type == "charge" ||
                      (type == "payment" && debt.type != "credit_card")) ...[
                    if (categoryItems.isEmpty)
                      const Text("Voce nao tem categorias de gasto.")
                    else
                      CategoryPicker(
                        label: "Categoria",
                        items: categoryItems,
                        value: categoryId,
                        onSelected: (item) =>
                            setState(() => categoryId = item.id),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (accountItems.isEmpty)
                    const Text("Voce nao tem contas ativas.")
                  else
                    AccountPicker(
                      label: "Conta",
                      items: accountItems,
                      value: accountId,
                      onSelected: (item) => setState(() => accountId = item.id),
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
                    decoration: const InputDecoration(
                      labelText: "Nota (opcional)",
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: "Salvar",
                    onPressed:
                        (accountItems.isEmpty ||
                            (type == "charge" &&
                                (categoryId == null || categoryItems.isEmpty)))
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

    if ((type == "charge" ||
            (type == "payment" && debt.type != "credit_card")) &&
        categoryId == null) {
      if (context.mounted) {
        showStandardSnackbar(context, "Falta escolher uma categoria");
      }
      return;
    }

    final error = await controller.createDebtTransaction(
      debtId: debt.id,
      date: date,
      type: type,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
    );

    if (error != null && context.mounted) {
      showStandardSnackbar(context, error);
    }
  }

  Future<void> _openHistoryDialog(
    BuildContext context,
    DebtsController controller,
    String debtId,
  ) async {
    final now = DateTime.now();
    final month = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final history = await controller.loadHistory(debtId, month: month);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Historial do mês"),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? const Text("Nenhum movimento este mês.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final tx = history[index];
                    final isCharge = tx.type == "charge";
                    final isPayment = tx.type == "payment";
                    return ListTile(
                      title: Text(
                        isCharge
                            ? "Compra"
                            : isPayment
                            ? "Pagamento"
                            : tx.type,
                      ),
                      subtitle: Text(
                        "${formatDate(tx.date)}${tx.note != null ? ' • ${tx.note}' : ''}",
                      ),
                      trailing: Text(
                        "${isPayment ? '-' : '+'}${formatMoney(tx.amount)}",
                        style: TextStyle(
                          color: isPayment ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final double amountDue;
  final double creditBalance;
  final double paymentsThisMonth;
  final DateTime? nextDueDate;
  final VoidCallback onCharge;
  final VoidCallback onPayment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onHistory;

  const _DebtCard({
    required this.debt,
    required this.amountDue,
    required this.creditBalance,
    required this.paymentsThisMonth,
    required this.nextDueDate,
    required this.onCharge,
    required this.onPayment,
    required this.onEdit,
    required this.onDelete,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final dueLabel = nextDueDate == null
        ? "Sem vencimento"
        : "Vence ${formatDate(nextDueDate!)}";

    // Main display logic
    Widget mainContent;
    if (amountDue == 0) {
      mainContent = Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Text(
              "Em dia ✅",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    } else {
      mainContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Saldo a pagar",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatMoney(amountDue),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
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
            mainContent,
            const SizedBox(height: AppSpacing.xs),
            Text(
              "$dueLabel • ${debt.currency}",
              style: const TextStyle(color: AppColors.muted),
            ),
            if (creditBalance > 0) ...[
              const SizedBox(height: 4),
              Text(
                "Saldo a favor: ${formatMoney(creditBalance)}",
                style: const TextStyle(
                  color: Colors.green, // or a distinct color indicating credit
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
            if (paymentsThisMonth > 0) ...[
              const SizedBox(height: 4),
              Text(
                "Pagamentos este mês: ${formatMoney(paymentsThisMonth)}",
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
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
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: onHistory,
              icon: const Icon(Icons.history),
              label: const Text("Ver historial"),
            ),
          ],
        ),
      ),
    );
  }
}

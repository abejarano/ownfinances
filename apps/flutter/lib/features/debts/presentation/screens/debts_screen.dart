import "package:flutter/material.dart";
import "package:provider/provider.dart";

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
      appBar: AppBar(title: const Text("Dividas"), leading: const BackButton()),
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
                    return _DebtCard(
                      debt: item,
                      onCharge: () =>
                          _openDebtTransactionForm(context, item, "charge"),
                      onPayment: () async {
                        if (item.amountDue == 0) {
                          // Confirmation dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Tudo pago ✅"),
                              content: const Text(
                                "Você não tem saldo a pagar neste cartão. Se pagar agora, este valor vira crédito para abater compras futuras.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancelar"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Pagar mesmo assim"),
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
                              title: const Text("Conta não vinculada"),
                              content: const Text(
                                "Para pagar a fatura, você precisa vincular uma conta do tipo 'Cartão de Crédito' a esta dívida.",
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
                      onHistory: () => Navigator.pushNamed(
                        context,
                        "/debts/${item.id}/history",
                      ),
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
    final initialBalanceController = TextEditingController(
      text: item?.initialBalance != null
          ? formatMoney(item!.initialBalance!)
          : "",
    );
    String type = item?.type ?? "credit_card";
    bool isActive = item?.isActive ?? true;

    // Initialize with existing inputs
    String? linkedAccountId = item?.linkedAccountId;
    String? paymentAccountId = item?.paymentAccountId;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final accountsState = context.watch<AccountsController>().state;

        // 1. Credit Card Accounts (for linkedAccountId)
        final creditCardAccounts = accountsState.items
            .where((a) => a.type == "credit_card")
            .map((a) => PickerItem(id: a.id, label: a.name))
            .toList();

        // 2. Paying Accounts (for paymentAccountId) - Bank, Cash, etc.
        final payingAccounts = accountsState.items
            .where((a) => ["bank", "cash", "wallet", "broker"].contains(a.type))
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

                  // --- ACCOUNT SELECTION LOGIC ---
                  if (type == "credit_card") ...[
                    const SizedBox(height: AppSpacing.sm),
                    if (creditCardAccounts.isEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Você não tem contas do tipo 'Cartão de Crédito'.",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Criar conta Cartão agora"),
                            onPressed: () => _createQuickAccount(
                              context,
                              "credit_card",
                              (id) => setState(() => linkedAccountId = id),
                            ),
                          ),
                        ],
                      )
                    else
                      AccountPicker(
                        label: "Conta do cartão (Onde caem as compras)",
                        items: creditCardAccounts,
                        value: linkedAccountId,
                        onSelected: (item) =>
                            setState(() => linkedAccountId = item.id),
                      ),
                  ],

                  // --- MOVED UP: Initial Balance ---
                  const SizedBox(height: AppSpacing.sm),
                  if (item == null)
                    MoneyInput(
                      label: "Saldo atual (opcional)",
                      controller: initialBalanceController,
                      helperText:
                          "Se você já tem saldo a pagar neste cartão hoje, informe aqui. Se não, deixe 0.",
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MoneyInput(
                          label: "Saldo inicial",
                          controller: initialBalanceController,
                          enabled: false,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Saldo inicial não pode ser alterado. Ajuste registrando uma compra/pagamento.",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),

                  // Paying Account (Optional)
                  const SizedBox(height: AppSpacing.sm),
                  if (payingAccounts.isEmpty)
                    const Text(
                      "Sem contas bancárias/dinheiro para pagar a fatura.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AccountPicker(
                          label: "Conta pagadora padrão (Opcional)",
                          items: payingAccounts,
                          value: paymentAccountId,
                          onSelected: (item) =>
                              setState(() => paymentAccountId = item.id),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Conta sugerida quando você registrar o pagamento da fatura.",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  // ------------------------------
                  const SizedBox(height: AppSpacing.sm),

                  // --- ADVANCED SECTION ---
                  ExpansionTile(
                    title: const Text("Avançado (opcional)"),
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: false,
                    children: [
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
                    ],
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
                    isLoading: isSubmitting,
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              showStandardSnackbar(context, "Nome obrigatorio");
                              return;
                            }

                            if (type == "credit_card" &&
                                linkedAccountId == null) {
                              showStandardSnackbar(
                                context,
                                "Selecione a conta do cartão",
                              );
                              return;
                            }

                            final dueDay = int.tryParse(
                              dueDayController.text.trim(),
                            );
                            final minimumPayment = parseMoney(
                              minimumPaymentController.text.trim(),
                            );
                            final interest = double.tryParse(
                              interestController.text.trim(),
                            );

                            setState(() => isSubmitting = true);

                            String? error;
                            if (item == null) {
                              error = await controller.create(
                                name: name,
                                type: type,
                                linkedAccountId: linkedAccountId,
                                paymentAccountId: paymentAccountId,
                                currency: currencyController.text.trim().isEmpty
                                    ? "BRL"
                                    : currencyController.text.trim(),
                                dueDay: dueDay,
                                minimumPayment: minimumPayment > 0
                                    ? minimumPayment
                                    : null,
                                interestRateAnnual: interest,
                                initialBalance: parseMoney(
                                  initialBalanceController.text,
                                ),
                                isActive: isActive,
                              );
                            } else {
                              error = await controller.update(
                                id: item.id,
                                name: name,
                                type: type,
                                linkedAccountId: linkedAccountId,
                                paymentAccountId: paymentAccountId,
                                currency: currencyController.text.trim().isEmpty
                                    ? "BRL"
                                    : currencyController.text.trim(),
                                dueDay: dueDay,
                                minimumPayment: minimumPayment > 0
                                    ? minimumPayment
                                    : null,
                                interestRateAnnual: interest,
                                isActive: isActive,
                              );
                            }

                            if (context.mounted) {
                              setState(() => isSubmitting = false);
                              if (error != null) {
                                showStandardSnackbar(context, error);
                              } else {
                                Navigator.of(context).pop(); // Success
                              }
                            }
                          },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
    String? accountId = debt.paymentAccountId ?? lastAccountId;
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

            // Validate pre-selected accountId still exists
            if (accountId != null &&
                !accountItems.any((i) => i.id == accountId)) {
              accountId = null;
            }
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
                  if (type == "charge" && debt.type == "credit_card")
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        "Saindo do cartão: ${debt.name}",
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else if (accountItems.isEmpty)
                    const Text("Voce nao tem contas ativas.")
                  else
                    AccountPicker(
                      label: "Conta de onde sai o pagamento",
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
                  Builder(
                    builder: (context) {
                      final requiresAccount = type == "payment";
                      final requiresCategory =
                          type == "charge" ||
                          (type == "payment" && debt.type != "credit_card");

                      bool isValid = true;

                      // Check Account
                      if (requiresAccount && accountId == null) isValid = false;

                      // Check Category
                      if (requiresCategory && categoryId == null)
                        isValid = false;

                      return PrimaryButton(
                        label: "Salvar",
                        onPressed: isValid
                            ? () => Navigator.of(context).pop(true)
                            : null,
                      );
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

  Future<void> _createQuickAccount(
    BuildContext context,
    String type,
    Function(String) onCreated,
  ) async {
    final nameController = TextEditingController();
    final controller = context.read<AccountsController>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Criar conta rápida"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nome da conta"),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Salvar"),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final name = nameController.text.trim();
      final error = await controller.create(
        name: name,
        type: type,
        currency: "BRL",
        isActive: true,
      );
      if (error != null) {
        if (context.mounted) showStandardSnackbar(context, error);
      } else {
        // Find the newly created account to select it
        // We assume it's the first one matching name/type or just reload state
        // Since we are watching state in main form, it will update.
        // We need to find the ID to auto-select it.
        final newItem = controller.state.items.firstWhere(
          (a) => a.name == name && a.type == type,
          orElse: () => controller.state.items.first, // Fallback
        );
        onCreated(newItem.id);
      }
    }
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onCharge;
  final VoidCallback onPayment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onHistory;

  const _DebtCard({
    required this.debt,
    required this.onCharge,
    required this.onPayment,
    required this.onEdit,
    required this.onDelete,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Due Date Logic
    final dueLabel = debt.dueDay != null ? "Vence dia ${debt.dueDay}" : null;

    // 2. Main Number Logic
    Widget balanceWidget;
    if (debt.amountDue > 0) {
      balanceWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Saldo a pagar:",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            formatMoney(debt.amountDue),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      );
    } else {
      balanceWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Saldo a pagar:",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                formatMoney(0),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey, // Neutral
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Em dia ✅",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
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
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    debt.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),

            // Big Balance Display
            balanceWidget,

            const SizedBox(height: AppSpacing.sm),

            // Credit Balance
            if (debt.creditBalance > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "Crédito: ${formatMoney(debt.creditBalance)}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

            // Minimum Payment
            if (debt.amountDue > 0 &&
                debt.minimumPayment != null &&
                debt.minimumPayment! > 0)
              Text(
                "Mínimo: ${formatMoney(debt.minimumPayment!)}",
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),

            // Due Date
            if (dueLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  dueLabel,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            // Buttons
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
                    onPressed: () {
                      if (debt.amountDue == 0) {
                        _showZeroBalancePaymentModal(context, onPayment);
                      } else {
                        onPayment();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton.icon(
                onPressed: onHistory,
                icon: const Icon(Icons.history),
                label: const Text("Ver histórico"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showZeroBalancePaymentModal(
    BuildContext context,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tudo pago ✅"),
        content: const Text(
          "Você não tem saldo a pagar. Se pagar agora, vira crédito para abater compras futuras.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text("Pagar mesmo assim"),
          ),
        ],
      ),
    );
  }
}

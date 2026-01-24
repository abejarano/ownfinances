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
import "package:ownfinances/core/presentation/components/money_text.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DebtsController>();
    final state = context.watch<DebtsController>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.debtsTitle),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.debtsActiveLiabilities,
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
                          _openUnifiedTransactionForm(context, item, "charge"),
                      onPayment: () async {
                        if (item.amountDue == 0) {
                          // Confirmation dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                AppLocalizations.of(
                                  context,
                                )!.debtsDialogPaidTitle,
                              ),
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.debtsDialogPaidBody,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    AppLocalizations.of(context)!.commonCancel,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.debtsDialogPaidAction,
                                  ),
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
                              title: Text(
                                AppLocalizations.of(
                                  context,
                                )!.debtsDialogLinkTitle,
                              ),
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.debtsDialogLinkBody,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    AppLocalizations.of(context)!.commonCancel,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.debtsDialogLinkAction,
                                  ),
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

                        _openUnifiedTransactionForm(context, item, "payment");
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

    final _formKey = GlobalKey<FormState>();

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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item == null
                          ? AppLocalizations.of(context)!.debtsNew
                          : AppLocalizations.of(context)!.debtsEdit,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.debtsName,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(
                            context,
                          )!.commonNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.debtsType,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: "credit_card",
                          child: Text(
                            AppLocalizations.of(context)!.debtsTypeCreditCard,
                          ),
                        ),
                        DropdownMenuItem(
                          value: "loan",
                          child: Text(
                            AppLocalizations.of(context)!.debtsTypeLoan,
                          ),
                        ),
                        DropdownMenuItem(
                          value: "other",
                          child: Text(
                            AppLocalizations.of(context)!.debtsTypeOther,
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => type = value);
                        }
                      },
                    ),

                    // --- ACCOUNT SELECTION LOGIC ---
                    if (type == "credit_card") ...[
                      const SizedBox(height: AppSpacing.md),
                      if (creditCardAccounts.isEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.debtsNoCreditCardAccount,
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 13,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                )!.debtsCreateCardAccount,
                              ),
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
                          label: AppLocalizations.of(
                            context,
                          )!.debtsLinkedAccount,
                          items: creditCardAccounts,
                          value: linkedAccountId,
                          onSelected: (item) =>
                              setState(() => linkedAccountId = item.id),
                        ),
                    ],

                    // --- MOVED UP: Initial Balance ---
                    const SizedBox(height: AppSpacing.md),
                    if (item == null)
                      MoneyInput(
                        label: AppLocalizations.of(
                          context,
                        )!.debtsInitialBalanceCurrent,
                        controller: initialBalanceController,
                        helperText: AppLocalizations.of(
                          context,
                        )!.debtsInitialBalanceHelper,
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MoneyInput(
                            label: AppLocalizations.of(
                              context,
                            )!.debtsInitialBalance,
                            controller: initialBalanceController,
                            enabled: false,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.debtsInitialBalanceWarning,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),

                    // Paying Account (Optional)
                    const SizedBox(height: AppSpacing.md),
                    if (payingAccounts.isEmpty)
                      Text(
                        AppLocalizations.of(context)!.debtsNoPayingAccount,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AccountPicker(
                            label: AppLocalizations.of(
                              context,
                            )!.debtsPayingAccount,
                            items: payingAccounts,
                            value: paymentAccountId,
                            onSelected: (item) =>
                                setState(() => paymentAccountId = item.id),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.debtsPayingAccountHelper,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    // ------------------------------
                    const SizedBox(height: AppSpacing.md),

                    // --- Moeda & Vencimento (Moved out of Advanced) ---
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: currencyController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.accountsLabelCurrency,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: dueDayController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.debtsDueDate,
                              hintText: AppLocalizations.of(
                                context,
                              )!.debtsDueDateHint,
                            ),
                            validator: (value) {
                              final dueDay = int.tryParse(value?.trim() ?? "");
                              if (type == "credit_card") {
                                if (dueDay == null ||
                                    dueDay < 1 ||
                                    dueDay > 31) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.debtsDueDateError;
                                }
                              } else if (value != null &&
                                  value.isNotEmpty &&
                                  (dueDay == null ||
                                      dueDay < 1 ||
                                      dueDay > 31)) {
                                return AppLocalizations.of(
                                  context,
                                )!.debtsDueDateError;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // --- ADVANCED SECTION ---
                    ExpansionTile(
                      title: Text(AppLocalizations.of(context)!.debtsAdvanced),
                      tilePadding: EdgeInsets.zero,
                      initiallyExpanded: false,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        MoneyInput(
                          label: AppLocalizations.of(
                            context,
                          )!.debtsMinimumPayment,
                          controller: minimumPaymentController,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: interestController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.debtsInterestRate,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.of(context)!.commonActive),
                      value: isActive,
                      onChanged: (value) => setState(() => isActive = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: AppLocalizations.of(context)!.commonSave,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }

                              final name = nameController.text.trim();

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
                                  currency:
                                      currencyController.text.trim().isEmpty
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
                                  currency:
                                      currencyController.text.trim().isEmpty
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
              ),
            );
          },
        );
      },
    );
  }

  void _openUnifiedTransactionForm(
    BuildContext context,
    Debt debt,
    String operation, // "charge" or "payment"
  ) {
    if (debt.linkedAccountId == null) {
      showStandardSnackbar(
        context,
        AppLocalizations.of(context)!.debtsErrorNoLinkedAccount,
      );
      return;
    }

    final transaction = Transaction(
      id: "", // Temporary
      type: operation == "charge" ? "expense" : "transfer",
      date: DateTime.now(),
      amount: 0,
      currency: debt.currency,
      categoryId: null,
      fromAccountId: operation == "charge" ? debt.linkedAccountId : null,
      toAccountId: operation == "payment" ? debt.linkedAccountId : null,
      note: "",
      tags: [],
      status: "pending",
      clearedAt: null,
    );

    context.push("/transactions/new", extra: transaction);
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
        title: Text(AppLocalizations.of(context)!.debtsQuickAccountTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.debtsQuickAccountName,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.commonSave),
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
    final dueLabel = debt.dueDay != null
        ? AppLocalizations.of(context)!.debtsDueDayLabel(debt.dueDay!)
        : null;

    // 2. Main Number Logic
    Widget balanceWidget;
    if (debt.amountDue > 0) {
      balanceWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.debtsCurrentBill,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          MoneyText(
            value: debt.amountDue,
            symbol: debt.currency,
            color: AppColors.danger,
            variant: MoneyTextVariant.l,
          ),
        ],
      );
    } else if (debt.creditBalance > 0) {
      balanceWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.debtsAvailableCredit,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          MoneyText(
            value: debt.creditBalance,
            symbol: debt.currency,
            color: AppColors.success,
            variant: MoneyTextVariant.l,
          ),
        ],
      );
    } else {
      balanceWidget = Text(
        AppLocalizations.of(context)!.debtsAllPaid,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (dueLabel != null)
                        Text(
                          dueLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onHistory,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == "edit") onEdit();
                    if (value == "delete") onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 16),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.commonEdit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.commonDelete,
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            // Balance
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [Expanded(child: balanceWidget)]),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: AppLocalizations.of(context)!.debtsActionCharge,
                    onPressed: onCharge,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: AppLocalizations.of(context)!.debtsActionPay,
                    icon: Icons.check,
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

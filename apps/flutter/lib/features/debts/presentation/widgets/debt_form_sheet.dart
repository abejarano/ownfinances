import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/debts/application/controllers/debts_controller.dart";
import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class DebtFormSheet extends StatefulWidget {
  final Debt? item;

  const DebtFormSheet({
    super.key,
    this.item,
  });

  @override
  State<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _currencyController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _minimumPaymentController;
  late final TextEditingController _interestController;
  late final TextEditingController _initialBalanceController;

  late String _type;
  late bool _isActive;
  String? _linkedAccountId;
  String? _paymentAccountId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? "");
    _currencyController = TextEditingController(
      text: item?.currency ?? "BRL",
    );
    _dueDayController = TextEditingController(
      text: item?.dueDay?.toString() ?? "",
    );
    _minimumPaymentController = TextEditingController(
      text: item?.minimumPayment != null
          ? formatMoney(item!.minimumPayment!)
          : "",
    );
    _interestController = TextEditingController(
      text: item?.interestRateAnnual?.toString() ?? "",
    );
    _initialBalanceController = TextEditingController(
      text: item?.initialBalance != null
          ? formatMoney(item!.initialBalance!)
          : "",
    );

    _type = item?.type ?? "credit_card";
    _isActive = item?.isActive ?? true;
    _linkedAccountId = item?.linkedAccountId;
    _paymentAccountId = item?.paymentAccountId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    _dueDayController.dispose();
    _minimumPaymentController.dispose();
    _interestController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
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
      final res = await controller.create(
        name: name,
        type: type,
        currency: "BRL",
        isActive: true,
      );
      if (res.error != null) {
        if (context.mounted) showStandardSnackbar(context, res.error!);
      } else {
        if (res.account != null) {
          onCreated(res.account!.id);
        }
      }
    }
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final controller = context.read<DebtsController>();
    final name = _nameController.text.trim();

    if (_type == "credit_card" && _linkedAccountId == null) {
      showStandardSnackbar(context, l10n.debtsErrorSelectAccount);
      return;
    }

    final dueDay = int.tryParse(_dueDayController.text.trim());
    final minimumPayment = parseMoney(_minimumPaymentController.text.trim());
    final interest = double.tryParse(_interestController.text.trim());

    setState(() => _isSubmitting = true);

    String? error;
    if (widget.item == null) {
      error = await controller.create(
        name: name,
        type: _type,
        linkedAccountId: _linkedAccountId,
        paymentAccountId: _paymentAccountId,
        currency: _currencyController.text.trim().isEmpty
            ? "BRL"
            : _currencyController.text.trim(),
        dueDay: dueDay,
        minimumPayment: minimumPayment > 0 ? minimumPayment : null,
        interestRateAnnual: interest,
        initialBalance: parseMoney(_initialBalanceController.text),
        isActive: _isActive,
      );
    } else {
      error = await controller.update(
        id: widget.item!.id,
        name: name,
        type: _type,
        linkedAccountId: _linkedAccountId,
        paymentAccountId: _paymentAccountId,
        currency: _currencyController.text.trim().isEmpty
            ? "BRL"
            : _currencyController.text.trim(),
        dueDay: dueDay,
        minimumPayment: minimumPayment > 0 ? minimumPayment : null,
        interestRateAnnual: interest,
        isActive: _isActive,
      );
    }

    if (!context.mounted) return;
    setState(() => _isSubmitting = false);
    if (error != null) {
      showStandardSnackbar(context, error);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accountsState = context.watch<AccountsController>().state;

    final creditCardAccounts = accountsState.items
        .where((a) => a.type == "credit_card")
        .map((a) => PickerItem(id: a.id, label: a.name))
        .toList();

    final payingAccounts = accountsState.items
        .where((a) => ["bank", "cash", "wallet", "broker"].contains(a.type))
        .map((a) => PickerItem(id: a.id, label: a.name))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item == null ? l10n.debtsNew : l10n.debtsEdit,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.debtsName,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.commonNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(
                labelText: l10n.debtsType,
              ),
              items: [
                DropdownMenuItem(
                  value: "credit_card",
                  child: Text(l10n.debtsTypeCreditCard),
                ),
                DropdownMenuItem(
                  value: "loan",
                  child: Text(l10n.debtsTypeLoan),
                ),
                DropdownMenuItem(
                  value: "other",
                  child: Text(l10n.debtsTypeOther),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            if (_type == "credit_card") ...[
              const SizedBox(height: AppSpacing.md),
              if (creditCardAccounts.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.debtsNoCreditCardAccount,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(l10n.debtsCreateCardAccount),
                      onPressed: () => _createQuickAccount(
                        context,
                        "credit_card",
                        (id) => setState(() => _linkedAccountId = id),
                      ),
                    ),
                  ],
                )
              else
                AccountPicker(
                  label: l10n.debtsLinkedAccount,
                  items: creditCardAccounts,
                  value: _linkedAccountId,
                  onSelected: (item) =>
                      setState(() => _linkedAccountId = item.id),
                ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (widget.item == null)
              MoneyInput(
                label: l10n.debtsInitialBalanceCurrent,
                controller: _initialBalanceController,
                helperText: l10n.debtsInitialBalanceHelper,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MoneyInput(
                    label: l10n.debtsInitialBalance,
                    controller: _initialBalanceController,
                    enabled: false,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.debtsInitialBalanceWarning,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            if (payingAccounts.isEmpty)
              Text(
                l10n.debtsNoPayingAccount,
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
                    label: l10n.debtsPayingAccount,
                    items: payingAccounts,
                    value: _paymentAccountId,
                    onSelected: (item) =>
                        setState(() => _paymentAccountId = item.id),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.debtsPayingAccountHelper,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _currencyController,
                    decoration: InputDecoration(
                      labelText: l10n.accountsLabelCurrency,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _dueDayController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.debtsDueDate,
                      hintText: l10n.debtsDueDateHint,
                    ),
                    validator: (value) {
                      final dueDay = int.tryParse(value?.trim() ?? "");
                      if (_type == "credit_card") {
                        if (dueDay == null || dueDay < 1 || dueDay > 31) {
                          return l10n.debtsDueDateError;
                        }
                      } else if (value != null &&
                          value.isNotEmpty &&
                          (dueDay == null || dueDay < 1 || dueDay > 31)) {
                        return l10n.debtsDueDateError;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ExpansionTile(
              title: Text(l10n.debtsAdvanced),
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: false,
              children: [
                const SizedBox(height: AppSpacing.md),
                MoneyInput(
                  label: l10n.debtsMinimumPayment,
                  controller: _minimumPaymentController,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _interestController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.debtsInterestRate,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.commonActive),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.commonSave,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : () => _submit(context),
            ),
          ],
        ),
      ),
    );
  }
}

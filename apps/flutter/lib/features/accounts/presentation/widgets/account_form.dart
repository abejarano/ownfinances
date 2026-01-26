import 'package:flutter/material.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/core/utils/currency_utils.dart';
import 'package:ownfinances/features/banks/application/controllers/banks_controller.dart';
import 'package:ownfinances/features/banks/domain/entities/bank.dart';
import 'package:ownfinances/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/money_input.dart';
import "package:ownfinances/core/presentation/components/pickers.dart";

class AccountForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController? currencyController;
  final String accountType;
  final ValueChanged<String> onTypeChanged;
  final String? bankType;
  final ValueChanged<String?> onBankTypeChanged;
  final bool isActive;
  final ValueChanged<bool>? onActiveChanged;
  final bool showCurrencySelector;
  final bool showActiveSwitch;
  final String? currency; // For bank filtering in Wizard (if explicit)
  final TextEditingController? initialBalanceController;

  const AccountForm({
    super.key,
    required this.nameController,
    required this.accountType,
    required this.onTypeChanged,
    this.currencyController,
    this.bankType,
    required this.onBankTypeChanged,
    this.isActive = true,
    this.onActiveChanged,
    this.showCurrencySelector = false,
    this.showActiveSwitch = false,
    this.currency,
    this.initialBalanceController,
  });

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  String? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    // Pre-load banks if needed (or rely on parent?)
    // If parent calls load, good. If not, safe to call here?
    // Parent might have criteria (country).
    // Let's assume parent manages loading if specific criteria needed.
    // But for AccountsScreen it loads all?
    _syncSelectedCurrency();
  }

  @override
  void didUpdateWidget(covariant AccountForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currencyController != widget.currencyController) {
      setState(_syncSelectedCurrency);
    }
  }

  void _syncSelectedCurrency() {
    final controller = widget.currencyController;
    if (controller == null) return;
    final normalized = controller.text.trim().toUpperCase();
    if (normalized.isEmpty) {
      _selectedCurrency = "BRL";
      controller.text = "BRL";
    } else if (CurrencyUtils.commonCurrencies.contains(normalized)) {
      _selectedCurrency = normalized;
      controller.text = normalized;
    } else {
      _selectedCurrency = "OTHER";
      controller.text = normalized;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Determine currency for filtering banks if possible
    // Use widget.currency OR widget.currencyController text
    final effectiveCurrency =
        widget.currency ??
        (widget.currencyController?.text.isNotEmpty == true
            ? widget.currencyController!.text
            // Fallback? AccountsScreen loads all usually or defaults to BRL
            : "BRL");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.nameController,
          decoration: InputDecoration(labelText: l10n.accountNameLabel),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          value: widget.accountType,
          decoration: InputDecoration(labelText: l10n.accountTypeLabel),
          items: [
            DropdownMenuItem(value: "bank", child: Text(l10n.accountTypeBank)),
            DropdownMenuItem(value: "cash", child: Text(l10n.accountTypeCash)),
            DropdownMenuItem(
              value: "wallet",
              child: Text(l10n.accountTypeWallet),
            ),
            DropdownMenuItem(
              value: "broker",
              child: Text(l10n.accountsTypeBroker),
            ),
            DropdownMenuItem(
              value: "credit_card",
              child: Text(l10n.accountsTypeCard),
            ),
          ],
          onChanged: (v) => v != null ? widget.onTypeChanged(v) : null,
        ),
        if (widget.accountType == 'bank') ...[
          const SizedBox(height: AppSpacing.md),
          Builder(
            builder: (context) {
              final banksState = context.watch<BanksController>();
              // Only show loading if empty and loading?
              // Or just show dropdown with what we have.

              return DropdownButtonFormField<String>(
                value: widget.bankType,
                decoration: InputDecoration(
                  labelText: l10n.accountsLabelBank,
                  hintText: "Selecione o banco",
                ),
                items: [
                  ...banksState.banks.map(
                    (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                  ),
                ],
                onChanged: widget.onBankTypeChanged,
              );
            },
          ),
        ],

        if (widget.showCurrencySelector &&
            widget.currencyController != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildCurrencySelector(context, l10n),
        ],

        if (widget.showActiveSwitch && widget.onActiveChanged != null) ...[
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.commonActive),
            value: widget.isActive,
            onChanged: widget.onActiveChanged,
          ),
        ],
        if (widget.initialBalanceController != null) ...[
          const SizedBox(height: AppSpacing.md),
          MoneyInput(
            controller: widget.initialBalanceController!,
            label: l10n.onboardingFieldInitialBalance,
            helperText: l10n.onboardingHelperInitialBalance,
            currencySymbol: effectiveCurrency,
          ),
        ],
      ],
    );
  }

  Widget _buildCurrencySelector(BuildContext context, AppLocalizations l10n) {
    final controller = widget.currencyController!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrencyPickerField(
          label: l10n.accountsLabelCurrency,
          value: _selectedCurrency,
          onSelected: (value) {
            setState(() {
              _selectedCurrency = value;
              if (value != null) {
                if (value != "OTHER") {
                  controller.text = value;
                } else if (CurrencyUtils.commonCurrencies.contains(
                  controller.text,
                )) {
                  controller.text = "";
                }
              }
            });
          },
        ),
        if (_selectedCurrency == "OTHER") ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.accountsLabelCurrencyCode,
              hintText: l10n.accountsHintCurrencyCode,
              helperText: l10n.accountsHelperCurrencyCode,
            ),
            onChanged: (value) {
              final normalized = value.trim().toUpperCase();
              if (normalized != value) {
                controller
                  ..text = normalized
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: normalized.length),
                  );
              }
              setState(() {});
            },
          ),
        ],
      ],
    );
  }
}

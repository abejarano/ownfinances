import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class ExpenseTransactionSection extends StatelessWidget {
  final List<PickerItem> accountItems;
  final List<PickerItem> categoryItems;
  final String? fromAccountId;
  final String? categoryId;
  final bool isCard;
  final void Function(PickerItem item) onAccountSelected;
  final void Function(PickerItem item) onCategorySelected;

  const ExpenseTransactionSection({
    super.key,
    required this.accountItems,
    required this.categoryItems,
    required this.fromAccountId,
    required this.categoryId,
    required this.isCard,
    required this.onAccountSelected,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Column(
      children: [
        AccountPicker(
          label: isCard
              ? localization.transactionFormInvoiceSource
              : localization.transactionFormLabelSource,
          items: accountItems,
          value: fromAccountId,
          onSelected: onAccountSelected,
        ),
        const SizedBox(height: 16),
        CategoryPicker(
          label: isCard
              ? localization.transactionFormCategoryPurchase
              : localization.transactionsLabelCategory,
          items: categoryItems,
          value: categoryId,
          onSelected: onCategorySelected,
        ),
      ],
    );
  }
}

class IncomeTransactionSection extends StatelessWidget {
  final List<PickerItem> accountItems;
  final List<PickerItem> categoryItems;
  final String? toAccountId;
  final String? categoryId;
  final void Function(PickerItem item) onAccountSelected;
  final void Function(PickerItem item) onCategorySelected;

  const IncomeTransactionSection({
    super.key,
    required this.accountItems,
    required this.categoryItems,
    required this.toAccountId,
    required this.categoryId,
    required this.onAccountSelected,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Column(
      children: [
        AccountPicker(
          label: localization.transactionsLabelEntryAccount,
          items: accountItems,
          value: toAccountId,
          onSelected: onAccountSelected,
        ),
        const SizedBox(height: 16),
        CategoryPicker(
          label: localization.transactionsLabelCategoryOptional,
          items: categoryItems,
          value: categoryId,
          onSelected: onCategorySelected,
        ),
      ],
    );
  }
}

class TransferTransactionSection extends StatelessWidget {
  final List<PickerItem> accountItems;
  final String? fromAccountId;
  final String? toAccountId;
  final bool isTransferCardPayment;
  final bool showSameAccountError;
  final bool showDestinationPicker;
  final void Function(PickerItem item) onFromAccountSelected;
  final void Function(PickerItem item) onToAccountSelected;

  const TransferTransactionSection({
    super.key,
    required this.accountItems,
    required this.fromAccountId,
    required this.toAccountId,
    required this.isTransferCardPayment,
    required this.showSameAccountError,
    required this.showDestinationPicker,
    required this.onFromAccountSelected,
    required this.onToAccountSelected,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Column(
      children: [
        AccountPicker(
          label: localization.transactionsLabelSource,
          items: accountItems,
          value: fromAccountId,
          onSelected: onFromAccountSelected,
        ),
        const SizedBox(height: 16),
        if (showDestinationPicker) ...[
          AccountPicker(
            label: isTransferCardPayment
                ? localization.transactionFormInvoiceSource
                : localization.transactionsLabelDestination,
            items: accountItems,
            value: toAccountId,
            onSelected: onToAccountSelected,
          ),
          if (showSameAccountError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                localization.transactionFormValidationSameAccount,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

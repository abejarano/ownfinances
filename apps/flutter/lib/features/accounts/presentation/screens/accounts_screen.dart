import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";

import "package:ownfinances/core/utils/currency_utils.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";

import 'package:ownfinances/features/accounts/presentation/widgets/account_management_card.dart';
import 'package:ownfinances/l10n/app_localizations.dart';

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

    // Check for invalid currencies (legacy data)
    final accountsWithInvalidCurrency = state.items
        .where((a) => !CurrencyUtils.isValidCurrency(a.currency))
        .toList();
    final hasInvalidCurrency = accountsWithInvalidCurrency.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountsTitle),

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
            // Warning Banner for Invalid Currencies
            if (hasInvalidCurrency)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.accountsWarningCurrency,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.accountsWarningCurrencyDesc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        // CTA: Fix Logic
                        onPressed: () async {
                          // Find first invalid
                          final toFix = accountsWithInvalidCurrency.first;
                          // Open form
                          await _openForm(context, controller, item: toFix);
                          // On return, UI rebuilds and effectively loops if more exist.
                          // Actually _openForm is async and waits for pop.
                          // When it returns, the build method runs again if state changed?
                          // Not automatically unless controller triggers notifyListeners.
                          // _openForm calls controller.update which calls notifyListeners.
                          // So the screen rebuilds, re-calculates accountsWithInvalidCurrency.
                          // If still has invalid, banner persists.
                          // For "Auto-Loop" UX (go to next immediately), we'd need a loop here.
                          // But since we are inside Build, we can't loop easily.
                          // Best approach: simpler is just let user tap again or implement a recursive helper.
                          // PO said: "automáticamente ir a la siguiente".
                          // Let's try a simple recursive call if we are mounted.
                          // But we are in onPressed.
                          if (context.mounted) {
                            // Let's just trigger a re-check or rely on rebuild.
                            // To auto-open next, we need to know if there are MORE.
                            // But we can't easily do it here without managing logic outside build.
                            // Let's stick to "One by One" via banner tap for safety,
                            // unless we implement a dedicated "Fix Flow" method.
                            // Given PO Req "ir a la siguiente", let's implement a while loop in a separate method.
                            _runFixFlow(context, controller, state.items);
                          }
                        },
                        child: Text(
                          AppLocalizations.of(context)!.accountsFixCurrency,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.accountsActive,
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
                  padding: const EdgeInsets.only(bottom: 80), // Fab space
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final balance = balanceMap[item.id] ?? 0.0;

                    return GestureDetector(
                      onLongPress: () async {
                        final confirmed = await _confirmDelete(
                          context,
                          title: AppLocalizations.of(
                            context,
                          )!.accountsDeleteTitle,
                          description: AppLocalizations.of(
                            context,
                          )!.accountsDeleteDesc,
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
                          showStandardSnackbar(
                            context,
                            AppLocalizations.of(context)!.accountsDeleted,
                          );
                        }
                      },
                      child: AccountManagementCard(
                        account: item,
                        balance: balance,
                        onEdit: () =>
                            _openForm(context, controller, item: item),
                      ),
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

  Future<void> _runFixFlow(
    BuildContext context,
    AccountsController controller,
    List<Account> items,
  ) async {
    // Find all invalids
    var invalids = items
        .where((a) => !CurrencyUtils.isValidCurrency(a.currency))
        .toList();

    while (invalids.isNotEmpty && context.mounted) {
      final toFix = invalids.first;
      await _openForm(context, controller, item: toFix);

      // Refetch state/items to see if fixed
      final newState = context.read<AccountsController>().state;
      invalids = newState.items
          .where((a) => !CurrencyUtils.isValidCurrency(a.currency))
          .toList();

      if (invalids.isEmpty && context.mounted) {
        showStandardSnackbar(
          context,
          AppLocalizations.of(context)!.accountsSuccessCurrencyFixed,
        );
        return;
      }

      // Ask to continue?
      // Required UX: "automáticamente ir a la siguiente".
      // So we just loop.
    }
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
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.commonDelete),
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
                    item == null
                        ? AppLocalizations.of(context)!.accountsNew
                        : AppLocalizations.of(context)!.accountsEdit,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.commonName,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.accountTypeLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: "cash",
                        child: Text(
                          AppLocalizations.of(context)!.accountsTypeMoney,
                        ),
                      ),
                      DropdownMenuItem(
                        value: "bank",
                        child: Text(
                          AppLocalizations.of(context)!.accountsTypeBank,
                        ),
                      ),
                      DropdownMenuItem(
                        value: "wallet",
                        child: Text(
                          AppLocalizations.of(context)!.accountsTypeWallet,
                        ),
                      ),
                      DropdownMenuItem(
                        value: "broker",
                        child: Text(
                          AppLocalizations.of(context)!.accountsTypeBroker,
                        ),
                      ),
                      DropdownMenuItem(
                        value: "credit_card",
                        child: Text(
                          AppLocalizations.of(context)!.accountsTypeCard,
                        ),
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
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: bankType,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.accountsLabelBank,
                      ),
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
                        DropdownMenuItem(value: "wise", child: Text("Wise")),
                        DropdownMenuItem(value: "neon", child: Text("Neon")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          bankType = value;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  // Currency Selector
                  DropdownButtonFormField<String>(
                    value:
                        CurrencyUtils.isValidCurrency(currencyController.text)
                        ? (CurrencyUtils.commonCurrencies.contains(
                                currencyController.text,
                              )
                              ? currencyController.text
                              : "OTHER")
                        : "OTHER", // Default to OTHER if unknown/invalid so user sees the text field to fix it.
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.accountsLabelCurrency,
                    ),
                    items: [
                      ...CurrencyUtils.commonCurrencies.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(CurrencyUtils.formatCurrencyLabel(c)),
                        ),
                      ),
                      DropdownMenuItem(
                        value: "OTHER",
                        child: Text(
                          AppLocalizations.of(context)!.currencyOther,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          if (value != "OTHER") {
                            currencyController.text = value;
                          } else {
                            // If switching to OTHER and current was standard, clear it?
                            // Or keep it to edit? Let's clear if it was a standard one.
                            if (CurrencyUtils.commonCurrencies.contains(
                              currencyController.text,
                            )) {
                              currencyController.text = "";
                            }
                          }
                        });
                      }
                    },
                  ),

                  // "Other" Currency Input
                  if (!CurrencyUtils.commonCurrencies.contains(
                    currencyController.text,
                  )) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: currencyController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.accountsLabelCurrencyCode,
                        hintText: AppLocalizations.of(
                          context,
                        )!.accountsHintCurrencyCode,
                        helperText: AppLocalizations.of(
                          context,
                        )!.accountsHelperCurrencyCode,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
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
                    onPressed: () {
                      final cleanCurrency = currencyController.text
                          .trim()
                          .toUpperCase();
                      // Validation inside modal
                      if (!CurrencyUtils.isValidCurrency(cleanCurrency)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.accountsErrorCurrencyInvalid,
                            ),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      // If valid:
                      currencyController.text =
                          cleanCurrency; // update controller with cleaned value
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
    String currency = currencyController.text
        .trim()
        .toUpperCase(); // Force upper

    // Strict Validation Logic
    if (name.isEmpty) {
      if (context.mounted) {
        showStandardSnackbar(
          context,
          AppLocalizations.of(context)!.commonNameRequired,
        );
      }
      return;
    }

    if (!CurrencyUtils.isValidCurrency(currency)) {
      if (context.mounted) {
        showStandardSnackbar(
          context,
          AppLocalizations.of(context)!.accountsErrorCurrencyInvalid,
        );
      }
      // Re-open form? For now just return, user has to tap save again.
      // Better UX would be to validate before closing modal, but showModalBottomSheet returns on pop.
      // We can't prevent pop here easily without managing state differently inside the builder.
      // The current flow pops FIRST then validates.
      // To fix this without refactoring the whole modal flow to internal state management:
      // We should ideally move this validation INSIDE the modal's "Salvar" button.
      return;
    }

    // If it's a known currency, ensure format is clean (just code)
    // Actually the selector sets the code, or the text field sets the code.
    // Logic already uppercased it.

    String? error;
    if (item == null) {
      error = await controller.create(
        name: name,
        type: type,
        currency: currency,
        isActive: isActive,
        bankType: type == "bank" ? bankType : null,
      );
    } else {
      error = await controller.update(
        id: item.id,
        name: name,
        type: type,
        currency: currency,
        isActive: isActive,
        bankType: type == "bank" ? bankType : null,
      );
    }
    if (error != null && context.mounted) {
      showStandardSnackbar(context, error);
    }
  }
}

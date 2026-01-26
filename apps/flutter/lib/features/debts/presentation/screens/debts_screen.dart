import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";

import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/debts/application/controllers/debts_controller.dart";
import "package:ownfinances/features/debts/domain/entities/debt.dart";
import "package:ownfinances/features/debts/presentation/widgets/debt_card.dart";
import "package:ownfinances/features/debts/presentation/widgets/debt_form_sheet.dart";
import "package:ownfinances/features/debts/presentation/widgets/debts_header.dart";
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
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/dashboard");
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            DebtsHeader(onRefresh: controller.load),
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
                    return DebtCard(
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
                            await _openDebtForm(context, item: item);
                          }
                          return;
                        }

                        _openUnifiedTransactionForm(context, item, "payment");
                      },
                      onEdit: () => _openDebtForm(context, item: item),
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
        onPressed: () => _openDebtForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openDebtForm(BuildContext context, {Debt? item}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DebtFormSheet(item: item);
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
}

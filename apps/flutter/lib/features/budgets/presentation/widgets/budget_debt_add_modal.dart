import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ownfinances/core/presentation/components/buttons.dart';
import 'package:ownfinances/core/presentation/components/money_input.dart';
// import 'package:ownfinances/core/presentation/components/forms.dart'; // Removed
import 'package:ownfinances/core/theme/app_theme.dart';
// import 'package:ownfinances/core/theme/app_theme.dart'; // Duplicate removed
import 'package:ownfinances/features/budgets/application/controllers/budget_controller.dart';
import 'package:ownfinances/features/budgets/domain/entities/budget.dart';
import 'package:ownfinances/features/debts/application/controllers/debts_controller.dart';
import 'package:ownfinances/features/debts/domain/entities/debt.dart';
import 'package:ownfinances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class BudgetDebtAddModal extends StatefulWidget {
  final BudgetDebtPayment? initialPayment;
  final String period;
  final DateTime date;

  const BudgetDebtAddModal({
    super.key,
    this.initialPayment,
    required this.period,
    required this.date,
  });

  @override
  State<BudgetDebtAddModal> createState() => _BudgetDebtAddModalState();
}

class _BudgetDebtAddModalState extends State<BudgetDebtAddModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedDebtId;
  bool _isLoading = false;

  // Helper to parse money value from controller
  double get _amountValue {
    final text = _amountController.text;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 0.0;
    return double.parse(digits) / 100;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialPayment != null) {
      _selectedDebtId = widget.initialPayment!.debtId;
      // MoneyInput expects user input format usually, or we set text directly.
      // If payment.amount is 100.00, we want "100,00" (if BRL).
      // We need the debt's currency to format correctly?
      // But _selectedDebtId is set, we can look it up?
      // Actually, MoneyInputFormatter handles digits.
      // If we set text to "10000", it might format to "100,00".
      // Let's assume input is raw digits for now or formatted.
      // Better: Use NumberFormat simpleCurrency to get string, then set it?
      // No, let's keep it simple: set text.
      // Since we don't have easy access to the formatter logic here without context,
      // let's try setting the double value formatted.
      // However, we don't have the debt yet to know currency.
      // We can find it from DebtsController.
      final debt = context
          .read<DebtsController>()
          .state
          .items
          .cast<Debt?>()
          .firstWhere((d) => d?.id == _selectedDebtId, orElse: () => null);
      if (debt != null) {
        final fmt = NumberFormat.simpleCurrency(name: debt.currency);
        _amountController.text = fmt.format(widget.initialPayment!.amount);
      } else {
        _amountController.text = widget.initialPayment!.amount.toStringAsFixed(
          2,
        );
      }
      _noteController.text = widget.initialPayment!.note ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDebtId == null) return;

    final amount = _amountValue;
    if (amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final payment = BudgetDebtPayment(
        debtId: _selectedDebtId!,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      // We update the local state directly. Saving happens when user clicks "Save" in the main screen
      // OR we can choose to save immediately. The prompt implies we are just organizing the plan.
      // Current BudgetController architecture has a manual "Save" button in the screen usually.
      // But looking at categories, addEntry saves immediately?
      // Re-reading BudgetController: addEntry DOES save immediately. updatePlannedDebt does NOT.
      // The user wants "Add Payment" flow. It probably should save immediately or update state.
      // "Edits are made to this single entry".
      // Let's stick to updating the state and let the main screen handle saving IF that was the pattern,
      // BUT `BudgetController.addEntry` (for categories) saves.
      // Given the UX "Add Payment" > "Modal", usually implies immediate action or explicit save.
      // The existing "Save Budget" button is for the whole screen.
      // However, for debts, let's treat it as state update first to match the existing "Save Plan" flow if possible,
      // but `BudgetDebtsTab` usually relies on `BudgetController`.

      // Actually, my `BudgetController.setPlannedDebt` sets `hasChanges: true`.
      // So I will just update the state and let the user save in the main screen?
      // Or should I auto-save? The detailed prompt didn't strictly specify auto-save vs manual save for this modal.
      // "BudgetScreen" has a global save.
      // I'll call `setPlannedDebt` and close. The `BudgetScreen` will show the "Save" button enabled.

      context.read<BudgetController>().setPlannedDebt(payment);

      if (mounted) context.pop();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final debtsState = context.read<DebtsController>().state;
    final budgetState = context.read<BudgetController>().state;

    // Filter active debts
    // If we are adding (not editing), filter out debts that are already in `plannedByDebt`.
    // If editing, include the current debt.
    final availableDebts = debtsState.items.where((d) {
      if (!d.isActive) return false;
      if (widget.initialPayment != null &&
          d.id == widget.initialPayment!.debtId)
        return true;
      if (budgetState.plannedByDebt.containsKey(d.id) &&
          budgetState.plannedByDebt[d.id]!.amount > 0)
        return false;
      return true;
    }).toList();

    // Find selected debt object to get currency
    final selectedDebt = debtsState.items.cast<Debt?>().firstWhere(
      (d) => d?.id == _selectedDebtId,
      orElse: () => null,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initialPayment == null
                    ? l10n.budgetsDebtModalTitleAdd
                    : l10n.budgetsDebtModalTitleEdit,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),

              // Debt Selector
              if (widget.initialPayment == null)
                DropdownButtonFormField<String>(
                  value: _selectedDebtId,
                  decoration: InputDecoration(
                    labelText: l10n.budgetsDebtModalLabelDebt,
                    border: const OutlineInputBorder(),
                  ),
                  items: availableDebts.map((debt) {
                    return DropdownMenuItem(
                      value: debt.id,
                      child: Text(debt.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDebtId = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? l10n.budgetsDebtModalErrorSelect : null,
                )
              else
                // Read-only field for editing
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.budgetsDebtModalLabelDebt,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  child: Text(selectedDebt?.name ?? ""),
                ),

              const SizedBox(height: AppSpacing.md),

              if (_selectedDebtId != null) ...[
                // Amount Input
                MoneyInput(
                  controller: _amountController,
                  currencySymbol: selectedDebt?.currency ?? '',
                  label: l10n.budgetsDebtModalLabelAmount,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.budgetsDebtModalCurrencyHelper,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Overpayment Warning
                // Note: We need debt summary properly loaded to check 'owed' amount.
                // Assuming DebtsController has loaded summaries.
                Builder(
                  builder: (context) {
                    // Check if DebtsController has summary for this debt
                    final summaries = context
                        .read<DebtsController>()
                        .state
                        .summaries;
                    final summary = summaries[_selectedDebtId];
                    if (summary != null) {
                      final owed = summary.balanceComputed;
                      if (_amountValue > owed) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.budgetsDebtModalWarningOverpay,
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Note Input
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.budgetsDebtModalLabelNote,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: AppSpacing.md),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.budgetsDebtModalPlanHelper,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              PrimaryButton(
                onPressed: _isLoading ? null : _submit,
                label: widget.initialPayment == null
                    ? l10n.budgetsDebtModalSubmitAdd
                    : l10n.budgetsDebtModalSubmitSave,
                isLoading: _isLoading,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

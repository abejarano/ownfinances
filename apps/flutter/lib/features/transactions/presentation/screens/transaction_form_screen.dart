import "package:flutter/material.dart";
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
import "package:ownfinances/features/recurring/application/controllers/recurring_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/templates/application/controllers/templates_controller.dart";
import "package:ownfinances/features/templates/domain/entities/transaction_template.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import 'package:ownfinances/l10n/app_localizations.dart';
import "package:provider/provider.dart";
import "package:ownfinances/features/transactions/presentation/helpers/transaction_form_validator.dart";
import "package:ownfinances/features/transactions/presentation/widgets/transaction_form_sections.dart";

class TransactionFormScreen extends StatefulWidget {
  final String? initialType;
  final TransactionTemplate? initialTemplate;
  final Transaction? initialTransaction;

  const TransactionFormScreen({
    super.key,
    this.initialType,
    this.initialTemplate,
    this.initialTransaction,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  // Form State
  String _type = "expense"; // expense, income, transfer
  double _amount = 0.0;
  double? _destinationAmount; // For manual conversion
  String? _categoryId;
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _date = DateTime.now();
  String _status = "pending"; // pending, cleared
  String? _debtId;

  // Optional / Advanced
  bool _isRecurring = false;
  String _recurrenceFrequency = "monthly";
  bool _saveAsTemplate = false;
  String _templateName = "";
  String _note = "";
  List<String> _tags = [];

  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _destinationAmountController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _templateNameController = TextEditingController();

  // Loading State
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Ensure debts are loaded
        context.read<DebtsController>().load();
      }
    });
  }

  void _initializeForm() {
    if (widget.initialTransaction != null) {
      final t = widget.initialTransaction!;
      _type = t.type;
      _amount = t.amount;
      _amountController.text = formatMoney(t.amount, withSymbol: false);
      if (t.destinationAmount != null) {
        _destinationAmount = t.destinationAmount;
        _destinationAmountController.text = formatMoney(
          t.destinationAmount!,
          withSymbol: false,
        );
      }
      _date = t.date;
      _categoryId = t.categoryId;
      _fromAccountId = t.fromAccountId;
      _toAccountId = t.toAccountId;
      _note = t.note ?? "";
      _noteController.text = _note;
      _tags = t.tags ?? [];
      _tagsController.text = _tags.join(", ");
      _status = t.status;
      _debtId = t.debtId;
    } else if (widget.initialTemplate != null) {
      final t = widget.initialTemplate!;
      _type = t.type;
      _amount = t.amount;
      _amountController.text = t.amount.toStringAsFixed(2);
      _categoryId = t.categoryId;
      _fromAccountId = t.fromAccountId;
      _toAccountId = t.toAccountId;
      _note = t.note ?? "";
      _noteController.text = _note;
    } else {
      _type = widget.initialType ?? "expense";
      // Load defaults
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Safe check for mounted before context access
        if (mounted) {
          final txState = context.read<TransactionsController>().state;
          setState(() {
            _categoryId = txState.lastCategoryId;
            _fromAccountId = txState.lastFromAccountId;
            _toAccountId = txState.lastToAccountId;
          });
        }
      });
    }

    _amountController.addListener(() {
      final val = parseMoney(_amountController.text);
      if (val != _amount) {
        _amount = val;
      }
    });

    _destinationAmountController.addListener(() {
      final val = parseMoney(_destinationAmountController.text);
      if (val != _destinationAmount) {
        _destinationAmount = val;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _destinationAmountController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    _templateNameController.dispose();
    super.dispose();
  }

  // --- Actions ---

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go("/dashboard");
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          // Ensure DatePicker uses Dark Calm theme
          data: AppTheme.darkCalm(),
          child: child!,
        );
      },
    );
    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  bool get _isConversionMode {
    if (_type != 'transfer') return false;
    if (_fromAccountId == null || _toAccountId == null) return false;

    final accounts = context.read<AccountsController>().state.items;
    final from = accounts.firstWhere(
      (a) => a.id == _fromAccountId,
      orElse: () => accounts.first,
    );
    final to = accounts.firstWhere(
      (a) => a.id == _toAccountId,
      orElse: () => accounts.first,
    );

    return from.currency != to.currency;
  }

  Debt? _findLinkedDebt(String? accountId) {
    final debts = context.read<DebtsController>().state.items;
    return _findDebtByAccount(accountId, debts);
  }

  Debt? _findDebtById(String? debtId, List<Debt> debts) {
    if (debtId == null) return null;
    try {
      return debts.firstWhere((d) => d.id == debtId);
    } catch (_) {
      return null;
    }
  }

  Debt? _findDebtByAccount(String? accountId, List<Debt> debts) {
    if (accountId == null) return null;
    try {
      return debts.firstWhere((d) =>
          d.linkedAccountId == accountId ||
          d.paymentAccountId == accountId);
    } catch (_) {
      return null;
    }
  }

  Debt? _findDebtForTransfer(List<Debt> debts) {
    final byId = _findDebtById(_debtId, debts);
    if (byId != null) {
      return byId;
    }
    return _findDebtByAccount(_toAccountId, debts);
  }

  bool get _isValid {
    final linkedDebt = _findLinkedDebt(_fromAccountId);
    return TransactionFormValidator.validate(
      type: _type,
      amount: _amount,
      fromAccountId: _fromAccountId,
      toAccountId: _toAccountId,
      categoryId: _categoryId,
      linkedDebt: linkedDebt,
      debtId: _debtId,
      isConversionMode: _isConversionMode,
      destinationAmount: _destinationAmount,
    );
  }

  Future<void> _save() async {
    if (!_isValid) return;

    if (_isRecurring && !_isSaving) {
      final confirmed = await _showRecurringConfirmation();
      if (!confirmed) return;
    }

    // Handle Debt Logic First
    final debtsController = context.read<DebtsController>();

    // Case 1: Expense on Credit Card -> Charge
    final expenseDebt = _type == "expense"
        ? _findLinkedDebt(_fromAccountId)
        : null;
    if (expenseDebt != null) {
      setState(() => _isSaving = true);
      try {
        final error = await debtsController.createDebtTransaction(
          debtId: expenseDebt.id,
          date: _date,
          type: "charge",
          amount: _amount,
          categoryId: _categoryId,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

        if (mounted) {
          if (error != null) {
            showStandardSnackbar(context, error);
          } else {
            showStandardSnackbar(
              context,
              AppLocalizations.of(context)!.transactionFormSuccessSave,
            ); // Generic success message or keep specific? "Compra registrada"
            _handleBack();
          }
        }
      } catch (e) {
        if (mounted)
          showStandardSnackbar(
            context,
            AppLocalizations.of(
              context,
            )!.transactionFormChargeError(e.toString()),
          );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
      return;
    }

    // Case 2: Transfer to Credit Card -> Payment
    final transferDebt = _type == "transfer"
        ? _findDebtForTransfer(
            context.read<DebtsController>().state.items,
          )
        : null;
    if (transferDebt != null) {
      setState(() => _isSaving = true);
      try {
        // In DebtTransaction, 'accountId' is the source of payment
        final error = await debtsController.createDebtTransaction(
          debtId: transferDebt.id,
          date: _date,
          type: "payment",
          amount: _amount,
          // Assuming no conversion for simple payment flow or it handles it
          accountId: _fromAccountId,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

        if (mounted) {
          if (error != null) {
            showStandardSnackbar(context, error);
          } else {
            showStandardSnackbar(
              context,
              AppLocalizations.of(context)!.transactionFormPaymentSuccess,
            );
            _handleBack();
          }
        }
      } catch (e) {
        if (mounted)
          showStandardSnackbar(
            context,
            AppLocalizations.of(
              context,
            )!.transactionFormPaymentError(e.toString()),
          );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
      return;
    }

    if (_isConversionMode) {
      final confirmed = await _showConversionConfirmation();
      if (!confirmed) return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        "type": _type,
        "date": _date.toIso8601String(),
        "amount": _amount,
        if (_isConversionMode) "destinationAmount": _destinationAmount,
        "categoryId": _type == "transfer" ? null : _categoryId,
        "fromAccountId": _type == "income" ? null : _fromAccountId,
        "toAccountId": _type == "expense" ? null : _toAccountId,
        "note": _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        "tags": _tagsController.text.isNotEmpty
            ? _tagsController.text.split(",").map((e) => e.trim()).toList()
            : null,
        "status": _status,
        if (_debtId != null) "debtId": _debtId,
      };

      final reportsController = context.read<ReportsController>();
      final period = reportsController.state.period;

      if (widget.initialTransaction != null) {
        final updated = await context
            .read<TransactionsController>()
            .updateWithImpact(
              id: widget.initialTransaction!.id,
              payload: payload,
              period: period,
            );
        if (updated?.impact != null) {
          reportsController.applyImpactFromJson(updated!.impact!);
        } else {
          await reportsController.load();
        }
        if (mounted) {
          showStandardSnackbar(
            context,
            AppLocalizations.of(context)!.transactionFormSuccessUpdate,
          );
          _handleBack();
        }
      } else {
        final created = await context
            .read<TransactionsController>()
            .createWithImpact(payload: payload, period: period);
        if (created == null) {
          if (mounted) {
            showStandardSnackbar(
              context,
              AppLocalizations.of(context)!.transactionFormErrorCreate,
            );
          }
          return;
        }

        context.read<TransactionsController>().rememberDefaults(
          created.transaction,
        );
        if (created.impact != null) {
          reportsController.applyImpactFromJson(created.impact!);
        } else {
          await reportsController.load();
        }

        if (_isRecurring) {
          final recurringController = context.read<RecurringController>();
          final nextStart = _nextRecurringStartDate(
            _date,
            _recurrenceFrequency,
          );
          final note = _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim();
          final tags = _tagsController.text.isNotEmpty
              ? _tagsController.text
                    .split(",")
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList()
              : null;

          final template = <String, dynamic>{
            "type": _type,
            "amount": _amount,
            if (_isConversionMode) "destinationAmount": _destinationAmount,
            "currency": created.transaction.currency,
            if (_type != "transfer") "categoryId": _categoryId,
            if (_type != "income") "fromAccountId": _fromAccountId,
            if (_type != "expense") "toAccountId": _toAccountId,
            if (note != null) "note": note,
            if (tags != null) "tags": tags,
          };

          final recurringPayload = {
            "frequency": _recurrenceFrequency,
            "interval": 1,
            "startDate": nextStart.toIso8601String(),
            "isActive": true,
            "template": template,
          };

          final rule = await recurringController.create(recurringPayload);
          if (mounted) {
            if (rule == null) {
              showStandardSnackbar(
                context,
                AppLocalizations.of(context)!.transactionFormRecurringError,
              );
            } else {
              showStandardSnackbar(
                context,
                AppLocalizations.of(context)!.transactionFormRecurringSuccess,
              );
            }
          }
        } else {
          if (mounted)
            showStandardSnackbar(
              context,
              AppLocalizations.of(context)!.transactionFormSuccessSave,
            );
        }

        if (_saveAsTemplate && _templateNameController.text.isNotEmpty) {
          await context.read<TemplatesController>().create({
            "name": _templateNameController.text,
            ...payload,
            "currency": "BRL", // TODO: Should infer from account?
          });
        }

        if (mounted) _handleBack();
      }
    } catch (e) {
      if (mounted)
        showStandardSnackbar(
          context,
          AppLocalizations.of(
            context,
          )!.transactionFormErrorUpdate(e.toString()),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmAccountChange() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF111C2F), // Surface 1
            title: Text(
              AppLocalizations.of(context)!.transactionFormChangeAccountTitle,
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              AppLocalizations.of(context)!.transactionFormChangeAccountDesc,
              style: const TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.65),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  AppLocalizations.of(context)!.commonCancel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  AppLocalizations.of(
                    context,
                  )!.transactionFormChangeAccountConfirm,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showRecurringConfirmation() async {
    final amountStr = formatMoney(_amount);
    final day = _date.day;

    // Attempt to get label
    String label = _noteController.text.isNotEmpty
        ? _noteController.text
        : AppLocalizations.of(
            context,
          )!.transactionFormTitleNew.replaceAll("Nova ", "");
    if (_categoryId != null) {
      try {
        final cats = context.read<CategoriesController>().state.items;
        final cat = cats.firstWhere((c) => c.id == _categoryId);
        if (_noteController.text.isEmpty) {
          label = cat.name;
        } else {
          label = "${cat.name} • $label";
        }
      } catch (_) {}
    }

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF111C2F),
            title: Text(
              AppLocalizations.of(context)!.transactionFormRecurringConfirm,
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.recurringNewRule,
                  // Or similar "You are creating a recurring rule"
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  "$label\n$amountStr\n${AppLocalizations.of(context)!.recurringSummaryDay(day)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.recurringAppDescription,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  AppLocalizations.of(context)!.commonBack,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  AppLocalizations.of(context)!.commonConfirm,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showConversionConfirmation() async {
    final accounts = context.read<AccountsController>().state.items;
    final from = accounts.firstWhere((a) => a.id == _fromAccountId);
    final to = accounts.firstWhere((a) => a.id == _toAccountId);

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF111C2F),
            title: Text(
              AppLocalizations.of(context)!.transactionFormConfirmConversion,
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfirmationRow(
                  AppLocalizations.of(context)!.transactionFormLabelYouSend,
                  "${from.currency} ${formatMoney(_amount, withSymbol: false)}",
                  "${from.name} (${from.currency})",
                  AppColors.warning,
                ),
                const SizedBox(height: 16),
                _buildConfirmationRow(
                  AppLocalizations.of(context)!.transactionFormLabelYouReceive,
                  "${to.currency} ${formatMoney(_destinationAmount ?? 0, withSymbol: false)}",
                  "${to.name} (${to.currency})",
                  AppColors.success,
                ),
                if (_amount > 0 && (_destinationAmount ?? 0) > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.transactionFormEffectiveRate(
                      from.currency,
                      to.currency,
                      ((_destinationAmount ?? 0) / _amount).toStringAsFixed(2),
                    ),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  AppLocalizations.of(context)!.commonBack,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  AppLocalizations.of(context)!.commonConfirm,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildConfirmationRow(
    String label,
    String value,
    String sub,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }

  void _onAccountChanged(bool isFrom, String? newAccountId) async {
    if (newAccountId == null) return;

    // Check if new account is blocked (Card as Source)
    if (_type == "transfer" && isFrom) {
      if (_findLinkedDebt(newAccountId) != null) {
        showStandardSnackbar(
          context,
          AppLocalizations.of(context)!.transactionFormLabelCardSourceError,
        );
        return;
      }
    }

    // Anti-Friction Check
    if (_amount > 0 || (_destinationAmount ?? 0) > 0) {
      final confirmed = await _confirmAccountChange();
      if (!confirmed) return; // Do nothing, keep old selection

      // If confirmed, update and clear
      setState(() {
        if (isFrom)
          _fromAccountId = newAccountId;
        else
          _toAccountId = newAccountId;
        _amount = 0;
        _destinationAmount = 0;
        _amountController.clear();
        _destinationAmountController.clear();
      });
      return;
    }

    // Normal change
    setState(() {
      if (isFrom)
        _fromAccountId = newAccountId;
      else
        _toAccountId = newAccountId;
    });
  }

  DateTime _nextRecurringStartDate(DateTime base, String frequency) {
    final dateOnly = DateTime(base.year, base.month, base.day);
    if (frequency == "weekly") {
      return dateOnly.add(const Duration(days: 7));
    }
    if (frequency == "yearly") {
      return DateTime(dateOnly.year + 1, dateOnly.month, dateOnly.day);
    }
    // monthly (default)
    return DateTime(dateOnly.year, dateOnly.month + 1, dateOnly.day);
  }

  // --- UI Components ---

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF14213A), // Inputs
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTypeBtn(
            AppLocalizations.of(context)!.transactionFormTypeExpense,
            "expense",
            AppColors.warning,
          ),
          _buildTypeBtn(
            AppLocalizations.of(context)!.transactionFormTypeIncome,
            "income",
            AppColors.success,
          ),
          _buildTypeBtn(
            AppLocalizations.of(context)!.transactionFormTypeTransfer,
            "transfer",
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBtn(String label, String value, Color color) {
    final isSelected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = value;
          // Cleanups when switching type
          if (value == 'transfer') {
            // If previously selected From is now invalid (Card), clear it
            if (_fromAccountId != null &&
                _findLinkedDebt(_fromAccountId) != null) {
              _fromAccountId = null;
            }
            _categoryId = null;
          }
          if (value == 'expense') {
            _toAccountId = null;
          }
          if (value == 'income') {
            _fromAccountId = null;
            _toAccountId = null; // Wait for user to pick
          }

          // Always clear amounts on type switch to stay safe
          _amount = 0;
          _destinationAmount = 0;
          _amountController.clear();
          _destinationAmountController.clear();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: color.withValues(alpha: 0.5))
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? color
                  : const Color.fromRGBO(255, 255, 255, 0.65), // Sec
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _darkInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.45)),
      // Tertiary
      filled: true,
      fillColor: const Color(0xFF14213A),
      // Inputs
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(255, 255, 255, 0.08),
        ), // Soft Border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(255, 255, 255, 0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = context.watch<CategoriesController>().state;
    final accountsState = context.watch<AccountsController>().state;
    final debtsState = context.watch<DebtsController>().state;

    final categoryItems = categoriesState.items
        .where((cat) => cat.kind == _type)
        .map((cat) => PickerItem(id: cat.id, label: cat.name))
        .toList();

    final accountItems = accountsState.items
        .map((acc) => PickerItem(id: acc.id, label: acc.name))
        .toList();

    final debtsItems = debtsState.items;

    // Determine Modes
    final isExpenseCard =
        _type == 'expense' && _findLinkedDebt(_fromAccountId) != null;
    final transferDebt =
        _type == 'transfer' ? _findDebtForTransfer(debtsItems) : null;
    final isTransferCardPayment =
        _type == 'transfer' && transferDebt != null;

    // --- Dynamic Title Checking ---
    String screenTitle = widget.initialTransaction != null
        ? AppLocalizations.of(context)!.transactionFormTitleEdit
        : AppLocalizations.of(context)!.transactionFormTitleNew;
    if (isExpenseCard)
      screenTitle = AppLocalizations.of(
        context,
      )!.transactionFormLabelCardPurchase;
    if (isTransferCardPayment)
      screenTitle = AppLocalizations.of(
        context,
      )!.transactionFormLabelInvoicePayment;

    // --- Display Logic ---
    bool showValueSection = false;
    bool showGuideBlock = false;

    // Labels & Currencies
    String labelValue1 = AppLocalizations.of(
      context,
    )!.transactionFormLabelTransferValue;
    String helper1 = "";
    String labelValue2 = "";
    String helper2 = "";

    // For Rate Calc
    String fromCurr = "";
    String toCurr = "";
    String mainCurrencySymbol = "R\$"; // Default

    if (_type == 'transfer') {
      if (_fromAccountId == null || _toAccountId == null) {
        // State 0
        showValueSection = false;
        showGuideBlock = true;
      } else {
        // Accounts Selected
        try {
          final from = accountsState.items.firstWhere(
            (a) => a.id == _fromAccountId,
          );
          final to = accountsState.items.firstWhere(
            (a) => a.id == _toAccountId,
          );

          showValueSection = true;
          mainCurrencySymbol = from.currency;

          if (isTransferCardPayment) {
            labelValue1 = AppLocalizations.of(
              context,
            )!.transactionFormLabelPaymentValue;
            helper1 = AppLocalizations.of(
              context,
            )!.transactionFormHelperPayment;
          } else if (from.currency == to.currency) {
            // State 1
            labelValue1 = AppLocalizations.of(
              context,
            )!.transactionFormLabelTransferValue;
            helper1 = AppLocalizations.of(
              context,
            )!.transactionFormHelperTransfer;
          } else {
            // State 2
            fromCurr = from.currency;
            toCurr = to.currency;
            labelValue1 = AppLocalizations.of(
              context,
            )!.transactionFormLabelSentValue(fromCurr);
            helper1 = AppLocalizations.of(context)!.transactionFormHelperSent;

            labelValue2 = AppLocalizations.of(
              context,
            )!.transactionFormLabelReceivedValue(toCurr);
            helper2 = AppLocalizations.of(
              context,
            )!.transactionFormHelperReceived;
          }
        } catch (_) {
          // Should not happen if data integrity valid
          showValueSection = true; // Fallback
        }
      }
    } else {
      // Income / Expense
      showValueSection = true;
      if (_type == 'expense' && _fromAccountId != null) {
        try {
          mainCurrencySymbol = accountsState.items
              .firstWhere((a) => a.id == _fromAccountId)
              .currency;
        } catch (_) {}
      } else if (_type == 'income' && _toAccountId != null) {
        try {
          mainCurrencySymbol = accountsState.items
              .firstWhere((a) => a.id == _toAccountId)
              .currency;
        } catch (_) {}
      }
    }

    if (_debtId != null) {
      showValueSection = true;
      showGuideBlock = false;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220), // App BG
      appBar: AppBar(
        title: Text(
          screenTitle,
          style: const TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.92), // Primary
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0D172A),
        // Top
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _handleBack,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- UX Header for Debt Modes ---
            if (isExpenseCard)
              Container(
                width: double.infinity,
                color: AppColors.warning.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.credit_card,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.transactionFormLabelDebtWarning,
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Selector
                  _buildTypeSelector(),
                  const SizedBox(height: 32),

                  // 2. Account Selectors (Always Visible)
                  if (_type == "expense") ...[
                    ExpenseTransactionSection(
                      accountItems: accountItems,
                      categoryItems: categoryItems,
                      fromAccountId: _fromAccountId,
                      categoryId: _categoryId,
                      isCard: isExpenseCard,
                      onAccountSelected: (item) =>
                          _onAccountChanged(true, item.id),
                      onCategorySelected: (item) =>
                          setState(() => _categoryId = item.id),
                    ),
                  ],
                  if (_type == "income") ...[
                    IncomeTransactionSection(
                      accountItems: accountItems,
                      categoryItems: categoryItems,
                      toAccountId: _toAccountId,
                      categoryId: _categoryId,
                      onAccountSelected: (item) =>
                          setState(() => _toAccountId = item.id),
                      onCategorySelected: (item) =>
                          setState(() => _categoryId = item.id),
                    ),
                  ],
                  if (_type == "transfer") ...[
                    TransferTransactionSection(
                      accountItems: accountItems,
                      fromAccountId: _fromAccountId,
                      toAccountId: _toAccountId,
                      isTransferCardPayment: isTransferCardPayment,
                      showDestinationPicker: _debtId == null,
                      showSameAccountError: _fromAccountId != null &&
                          _toAccountId != null &&
                          _fromAccountId == _toAccountId,
                      onFromAccountSelected: (item) =>
                          _onAccountChanged(true, item.id),
                      onToAccountSelected: (item) =>
                          _onAccountChanged(false, item.id),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // 3. Guide Block (State 0)
                  if (showGuideBlock)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111C2F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.swap_horiz,
                            color: Color.fromRGBO(255, 255, 255, 0.45),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.transactionFormLabelSelectSourceDest,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.transactionFormHelperSelectSourceDest,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 4. Value Inputs (Main + Optional Destination)
                  if (showValueSection) ...[
                    MoneyInput(
                      label: labelValue1,
                      controller: _amountController,
                      helperText: helper1,
                    ),

                    // Conversion Input (If needed)
                    if (labelValue2.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      MoneyInput(
                        label: labelValue2,
                        controller: _destinationAmountController,
                        helperText: helper2,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // 5. Date & Status (Always Visible)
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14213A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromRGBO(255, 255, 255, 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatDate(_date),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _status == "cleared",
                              activeColor: AppColors.success,
                              onChanged: (val) {
                                setState(() {
                                  _status = (val == true)
                                      ? "cleared"
                                      : "pending";
                                });
                              },
                              side: BorderSide(color: Colors.white54),
                            ),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.transactionFormLabelAlreadyCleared,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Visual Status Chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _status == "cleared"
                                    ? AppColors.success.withValues(alpha: 0.2)
                                    : Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _status == "cleared"
                                      ? AppColors.success
                                      : Colors.white24,
                                ),
                              ),
                              child: Text(
                                _status == "cleared"
                                    ? AppLocalizations.of(
                                        context,
                                      )!.transactionFormStatusCleared
                                    : AppLocalizations.of(
                                        context,
                                      )!.transactionFormStatusPending,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _status == "cleared"
                                      ? AppColors.success
                                      : Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.transactionFormHelperStatus,
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 6. Mais Opções (Note, Tags, Recurrence)
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!.transactionFormLabelMoreOptions,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _isRecurring
                              ? AppLocalizations.of(
                                  context,
                                )!.transactionFormLabelMoreOptionsRecurring
                              : AppLocalizations.of(
                                  context,
                                )!.transactionFormLabelMoreOptionsSubtitle,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        initiallyExpanded:
                            widget.initialTransaction != null ||
                            _noteController.text.isNotEmpty,
                        collapsedBackgroundColor: const Color(0xFF14213A),
                        backgroundColor: const Color(0xFF14213A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          TextFormField(
                            controller: _noteController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _darkInputDecoration(
                              AppLocalizations.of(
                                context,
                              )!.transactionFormLabelNote,
                            ),
                            maxLines: 2,
                          ),

                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _tagsController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _darkInputDecoration(
                              AppLocalizations.of(
                                context,
                              )!.transactionFormLabelTags,
                            ),
                          ),

                          const SizedBox(height: 16),

                          if (!isExpenseCard && !isTransferCardPayment) ...[
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                AppLocalizations.of(
                                  context,
                                )!.transactionFormLabelRepeat,
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                AppLocalizations.of(
                                  context,
                                )!.transactionFormHelperRepeat,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              value: _isRecurring,
                              activeColor: AppColors.primary,
                              onChanged: (val) =>
                                  setState(() => _isRecurring = val),
                            ),
                          ],

                          if (_isRecurring &&
                              !isExpenseCard &&
                              !isTransferCardPayment) ...[
                            const SizedBox(height: 8),
                            // Frequency Selector
                            Row(
                              children: [
                                _buildFreqChip(
                                  AppLocalizations.of(
                                    context,
                                  )!.transactionFormLabelFrequencyMonthly,
                                  "monthly",
                                ),
                                const SizedBox(width: 8),
                                _buildFreqChip(
                                  AppLocalizations.of(
                                    context,
                                  )!.transactionFormLabelFrequencyWeekly,
                                  "weekly",
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () =>
                                    context.push('/budget?tab=fixed'),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.transactionFormActionManageFixed,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              AppLocalizations.of(
                                context,
                              )!.transactionFormLabelSaveTemplate,
                              style: TextStyle(color: Colors.white),
                            ),
                            value: _saveAsTemplate,
                            activeColor: AppColors.primary,
                            onChanged: (val) =>
                                setState(() => _saveAsTemplate = val),
                          ),

                          if (_saveAsTemplate) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _templateNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _darkInputDecoration(
                                AppLocalizations.of(
                                  context,
                                )!.transactionFormLabelTemplateName,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: PrimaryButton(
                label: _isSaving
                    ? AppLocalizations.of(context)!.transactionFormActionSaving
                    : AppLocalizations.of(context)!.commonSave,
                isLoading: _isSaving,
                onPressed: _isValid ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreqChip(String label, String value) {
    final isSelected = _recurrenceFrequency == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _recurrenceFrequency = value);
      },
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFF14213A),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white60),
    );
  }
}

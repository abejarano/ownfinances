import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/recurring/application/controllers/recurring_controller.dart";
import "package:ownfinances/features/templates/application/controllers/templates_controller.dart";
import "package:ownfinances/features/templates/domain/entities/transaction_template.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";

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

  bool get _isValid {
    if (_type == 'transfer') {
      if (_fromAccountId == null || _toAccountId == null) return false;
      if (_fromAccountId == _toAccountId) return false;
      if (_amount <= 0) return false;
      if (_isConversionMode &&
          (_destinationAmount == null || _destinationAmount! <= 0))
        return false;
      return true;
    }
    // Basic check for other types
    if (_amount <= 0) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_isValid) return; // Should be disabled, but safe check

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
          showStandardSnackbar(context, "Transação atualizada com sucesso!");
          _handleBack();
        }
      } else {
        final created = await context
            .read<TransactionsController>()
            .createWithImpact(payload: payload, period: period);
        if (created == null) {
          if (mounted) {
            showStandardSnackbar(context, "Erro ao salvar a transação.");
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
                "Transação salva, mas não foi possível criar a recorrência.",
              );
            } else {
              showStandardSnackbar(
                context,
                "Transação salva e recorrência criada!",
              );
            }
          }
        } else {
          if (mounted) showStandardSnackbar(context, "Transação salva!");
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
      if (mounted) showStandardSnackbar(context, "Erro ao salvar: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmAccountChange() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF111C2F), // Surface 1
            title: const Text(
              "Alterar contas?",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Isso pode mudar a moeda e limpar os valores informados.",
              style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.65)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Alterar e limpar",
                  style: TextStyle(color: AppColors.primary),
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
            title: const Text(
              "Confirmar conversão",
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfirmationRow(
                  "Você envia:",
                  "${from.currency} ${formatMoney(_amount, withSymbol: false)}",
                  "${from.name} (${from.currency})",
                  AppColors.warning,
                ),
                const SizedBox(height: 16),
                _buildConfirmationRow(
                  "Você recebe:",
                  "${to.currency} ${formatMoney(_destinationAmount ?? 0, withSymbol: false)}",
                  "${to.name} (${to.currency})",
                  AppColors.success,
                ),
                if (_amount > 0 && (_destinationAmount ?? 0) > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Taxa efetiva: 1 ${from.currency} ≈ ${to.currency} ${((_destinationAmount ?? 0) / _amount).toStringAsFixed(2)}",
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
                child: const Text(
                  "Voltar",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Confirmar",
                  style: TextStyle(
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
          _buildTypeBtn("Despesa", "expense", AppColors.warning),
          _buildTypeBtn("Receita", "income", AppColors.success),
          _buildTypeBtn("Transf.", "transfer", AppColors.info),
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
          if (value == 'transfer') {
            _categoryId = null;
            // Clear inputs when switching type? Usually safer
            _amount = 0;
            _destinationAmount = 0;
            _amountController.clear();
            _destinationAmountController.clear();
          }
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
      labelStyle: const TextStyle(
        color: Color.fromRGBO(255, 255, 255, 0.45),
      ), // Tertiary
      filled: true,
      fillColor: const Color(0xFF14213A), // Inputs
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

    final categoryItems = categoriesState.items
        .where((cat) => cat.kind == _type)
        .map((cat) => PickerItem(id: cat.id, label: cat.name))
        .toList();

    final accountItems = accountsState.items
        .map((acc) => PickerItem(id: acc.id, label: acc.name))
        .toList();

    // --- Display Logic ---
    bool showValueSection = false;
    bool showGuideBlock = false;

    // Labels & Currencies
    String labelValue1 = "Valor";
    String helper1 = "Valor transferido";
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

          if (from.currency == to.currency) {
            // State 1
            labelValue1 = "Valor";
            helper1 = "Valor que sai da origem e entra no destino.";
          } else {
            // State 2
            fromCurr = from.currency;
            toCurr = to.currency;
            labelValue1 = "Você envia ($fromCurr)";
            helper1 = "Valor que sai da conta de origem.";

            labelValue2 = "Você recebe ($toCurr)";
            helper2 = "Valor que entra na conta de destino.";
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

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220), // App BG
      appBar: AppBar(
        title: Text(
          widget.initialTransaction != null
              ? "Editar Transação"
              : "Nova Transação",
          style: const TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.92), // Primary
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0D172A), // Top
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Selector
                  _buildTypeSelector(),
                  const SizedBox(height: 32),

                  // 2. Account Selectors (Always Visible)
                  if (_type == "expense") ...[
                    AccountPicker(
                      label: "Conta de Saída",
                      items: accountItems,
                      value: _fromAccountId,
                      onSelected: (item) =>
                          setState(() => _fromAccountId = item.id),
                    ),
                    const SizedBox(height: 16),
                    CategoryPicker(
                      label: "Categoria",
                      items: categoryItems,
                      value: _categoryId,
                      onSelected: (item) =>
                          setState(() => _categoryId = item.id),
                    ),
                  ],
                  if (_type == "income") ...[
                    AccountPicker(
                      label: "Conta de Entrada",
                      items: accountItems,
                      value: _toAccountId,
                      onSelected: (item) =>
                          setState(() => _toAccountId = item.id),
                    ),
                    const SizedBox(height: 16),
                    CategoryPicker(
                      label: "Categoria (Opcional)",
                      items: categoryItems,
                      value: _categoryId,
                      onSelected: (item) =>
                          setState(() => _categoryId = item.id),
                    ),
                  ],
                  if (_type == "transfer") ...[
                    AccountPicker(
                      label: "De (Origem)",
                      items: accountItems,
                      value: _fromAccountId,
                      onSelected: (item) => _onAccountChanged(true, item.id),
                    ),
                    const SizedBox(height: 16),
                    AccountPicker(
                      label: "Para (Destino)",
                      items: accountItems,
                      value: _toAccountId,
                      onSelected: (item) => _onAccountChanged(false, item.id),
                    ),

                    if (_fromAccountId != null &&
                        _fromAccountId == _toAccountId)
                      const Padding(
                        padding: EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          "Selecione contas diferentes.",
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                        ),
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
                            Icons.touch_app_outlined,
                            color: Color.fromRGBO(255, 255, 255, 0.45),
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Escolha as contas para continuar.",
                            style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.92),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Depois você informa o valor.",
                            style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.45),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 4. Value Section
                  if (showValueSection) ...[
                    // If Diff Currency (State 2) -> Info Block First
                    if (_isConversionMode) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(59, 130, 246, 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color.fromRGBO(59, 130, 246, 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "A Desquadra não converte automaticamente.",
                                    style: TextStyle(
                                      color: Color.fromRGBO(
                                        255,
                                        255,
                                        255,
                                        0.92,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Informe os valores como aconteceu na vida real.",
                                    style: TextStyle(
                                      color: Color.fromRGBO(
                                        255,
                                        255,
                                        255,
                                        0.65,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Input 1
                    Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: Theme.of(context)
                            .inputDecorationTheme
                            .copyWith(
                              labelStyle: const TextStyle(
                                color: Color.fromRGBO(255, 255, 255, 0.45),
                              ),
                            ),
                      ),
                      child: MoneyInput(
                        controller: _amountController,
                        label: _type == 'transfer' ? labelValue1 : "",
                        currencySymbol: mainCurrencySymbol,
                      ),
                    ),
                    if (_type == 'transfer')
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          helper1,
                          style: const TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.45),
                            fontSize: 12,
                          ),
                        ),
                      ),

                    // Input 2 (If Conversion)
                    if (_isConversionMode) ...[
                      const SizedBox(height: 24),
                      Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: Theme.of(context)
                              .inputDecorationTheme
                              .copyWith(
                                labelStyle: const TextStyle(
                                  color: Color.fromRGBO(255, 255, 255, 0.45),
                                ),
                              ),
                        ),
                        child: MoneyInput(
                          controller: _destinationAmountController,
                          label: labelValue2,
                          currencySymbol: toCurr,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          helper2,
                          style: const TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.45),
                            fontSize: 12,
                          ),
                        ),
                      ),

                      if (_amount > 0 && (_destinationAmount ?? 0) > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111C2F),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color.fromRGBO(255, 255, 255, 0.08),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Você enviou:",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "$fromCurr ${formatMoney(_amount, withSymbol: false)}",
                                    style: const TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Você recebeu:",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "$toCurr ${formatMoney(_destinationAmount!, withSymbol: false)}",
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                  height: 1,
                                  color: Color.fromRGBO(255, 255, 255, 0.08),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Taxa efetiva: 1 $fromCurr = ${((_destinationAmount ?? 0) / _amount).toStringAsFixed(2)} $toCurr",
                                    style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],

                  const SizedBox(height: 32),

                  // 5. Date & Status
                  // Copied from previous logic but matching new colors
                  // Date & Status Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14213A), // Inputs
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromRGBO(
                                  255,
                                  255,
                                  255,
                                  0.08,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Color.fromRGBO(255, 255, 255, 0.65),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatDate(_date),
                                  style: const TextStyle(
                                    color: Color.fromRGBO(255, 255, 255, 0.92),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14213A), // Inputs
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color.fromRGBO(255, 255, 255, 0.08),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _status,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF14213A),
                              style: const TextStyle(
                                color: Color.fromRGBO(255, 255, 255, 0.92),
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color.fromRGBO(255, 255, 255, 0.65),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "pending",
                                  child: Text("Pendente"),
                                ),
                                DropdownMenuItem(
                                  value: "cleared",
                                  child: Text("Confirmado"),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _status = val!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // More Options
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      iconTheme: const IconThemeData(
                        color: Color.fromRGBO(255, 255, 255, 0.65),
                      ),
                      textTheme: const TextTheme(
                        titleMedium: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 0.92),
                        ),
                      ),
                    ),
                    child: ExpansionTile(
                      title: const Text(
                        "Mais Opções",
                        style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 0.92),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      tilePadding: EdgeInsets.zero,
                      collapsedIconColor: Color.fromRGBO(255, 255, 255, 0.65),
                      children: [
                        const SizedBox(height: 16),
                        TextField(
                          controller: _noteController,
                          style: const TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.92),
                          ),
                          decoration: _darkInputDecoration("Observação"),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _tagsController,
                          style: const TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.92),
                          ),
                          decoration: _darkInputDecoration(
                            "Tags (separadas por vírgula)",
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text(
                            "Recorrência",
                            style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.92),
                            ),
                          ),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          value: _isRecurring,
                          onChanged: (v) => setState(() => _isRecurring = v),
                        ),
                        if (_isRecurring)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: const Text(
                              "A transação se repetirá mensalmente (padrão).",
                              style: TextStyle(
                                color: Color.fromRGBO(255, 255, 255, 0.45),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        SwitchListTile(
                          title: const Text(
                            "Salvar como Modelo",
                            style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.92),
                            ),
                          ),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          value: _saveAsTemplate,
                          onChanged: (v) => setState(() => _saveAsTemplate = v),
                        ),
                        if (_saveAsTemplate)
                          TextField(
                            controller: _templateNameController,
                            style: const TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.92),
                            ),
                            decoration: _darkInputDecoration("Nome do Modelo"),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer Action
            Padding(
              padding: const EdgeInsets.all(20),
              child: PrimaryButton(
                label: widget.initialTransaction != null
                    ? "Salvar Alterações"
                    : "Salvar Transação",
                onPressed: (_isSaving || !_isValid) ? null : _save,
                isLoading: _isSaving,
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

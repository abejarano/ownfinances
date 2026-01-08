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
  }

  @override
  void dispose() {
    _amountController.dispose();
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
          data: AppTheme.light().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  Future<void> _save() async {
    if (_amount <= 0) {
      showStandardSnackbar(context, "Por favor, insira um valor válido.");
      return;
    }

    if (_type == "transfer") {
      if (_fromAccountId == null || _toAccountId == null) {
        showStandardSnackbar(
          context,
          "Selecione as contas de origem e destino.",
        );
        return;
      }
    } else {
      if (_categoryId == null && _type != 'transfer') {
        showStandardSnackbar(context, "Selecione uma categoria.");
        return;
      }
      if (_type == "expense" && _fromAccountId == null) {
        showStandardSnackbar(context, "Selecione a conta de saída.");
        return;
      }
      if (_type == "income" && _toAccountId == null) {
        showStandardSnackbar(context, "Selecione a conta de entrada.");
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        "type": _type,
        "date": _date.toIso8601String(),
        "amount": _amount,
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
            "currency": "BRL",
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

  DateTime _nextRecurringStartDate(DateTime base, String frequency) {
    final dateOnly = DateTime(base.year, base.month, base.day);
    if (frequency == "weekly") {
      return dateOnly.add(const Duration(days: 7));
    }
    if (frequency == "yearly") {
      return DateTime(
        dateOnly.year + 1,
        dateOnly.month,
        dateOnly.day,
      );
    }
    // monthly (default)
    return DateTime(
      dateOnly.year,
      dateOnly.month + 1,
      dateOnly.day,
    );
  }

  // --- UI Components ---

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTypeBtn("Despesa", "expense", Colors.redAccent),
          _buildTypeBtn("Receita", "income", Colors.green),
          _buildTypeBtn("Transf.", "transfer", Colors.blue),
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
          if (value == 'transfer') _categoryId = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: color.withOpacity(0.5))
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? color : Colors.white70,
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
      labelStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Nova Transação",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
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
                  // Type Selector
                  _buildTypeSelector(),
                  const SizedBox(height: 32),

                  // Amount
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Valor",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // MoneyInput wrapping for color override if needed,
                        // but usually it uses Theme text color which is white in AppTheme
                        Theme(
                          data: Theme.of(context).copyWith(
                            inputDecorationTheme: Theme.of(context)
                                .inputDecorationTheme
                                .copyWith(
                                  // ensure consistent font size or style for the big amount
                                  labelStyle: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                          ),
                          child: MoneyInput(
                            controller: _amountController,
                            label: "",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Main Selectors
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
                      onSelected: (item) =>
                          setState(() => _fromAccountId = item.id),
                    ),
                    const SizedBox(height: 16),
                    AccountPicker(
                      label: "Para (Destino)",
                      items: accountItems,
                      value: _toAccountId,
                      onSelected: (item) =>
                          setState(() => _toAccountId = item.id),
                    ),
                  ],

                  const SizedBox(height: 24),

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
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatDate(_date),
                                  style: const TextStyle(
                                    color: Colors.white,
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
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _status,
                              isExpanded: true,
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(color: Colors.white),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white70,
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

                  // More Options (Simple Expandable or just Tiles)
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      iconTheme: const IconThemeData(color: Colors.white70),
                      textTheme: const TextTheme(
                        titleMedium: TextStyle(color: Colors.white),
                      ),
                    ),
                    child: ExpansionTile(
                      title: const Text(
                        "Mais Opções",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      tilePadding: EdgeInsets.zero,
                      collapsedIconColor: Colors.white70,
                      children: [
                        const SizedBox(height: 16),
                        TextField(
                          controller: _noteController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _darkInputDecoration("Observação"),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _tagsController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _darkInputDecoration(
                            "Tags (separadas por vírgula)",
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text(
                            "Recorrência",
                            style: TextStyle(color: Colors.white),
                          ),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          value: _isRecurring,
                          onChanged: (v) => setState(() => _isRecurring = v),
                        ),
                        if (_isRecurring)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: DropdownButtonFormField<String>(
                              value: _recurrenceFrequency,
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(color: Colors.white),
                              decoration: _darkInputDecoration("Frequência"),
                              items: const [
                                DropdownMenuItem(
                                  value: "weekly",
                                  child: Text("Semanal"),
                                ),
                                DropdownMenuItem(
                                  value: "monthly",
                                  child: Text("Mensal"),
                                ),
                                DropdownMenuItem(
                                  value: "yearly",
                                  child: Text("Anual"),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _recurrenceFrequency = v!),
                            ),
                          ),
                        SwitchListTile(
                          title: const Text(
                            "Salvar como Modelo",
                            style: TextStyle(color: Colors.white),
                          ),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          value: _saveAsTemplate,
                          onChanged: (v) => setState(() => _saveAsTemplate = v),
                        ),
                        if (_saveAsTemplate)
                          TextField(
                            controller: _templateNameController,
                            style: const TextStyle(color: Colors.white),
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
                label: _isSaving ? "Salvando..." : "Salvar Transação",
                onPressed: _isSaving ? null : _save,
                // PrimaryButton should adapt to theme or use primary color by default
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/cards.dart";
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/reports/domain/entities/report_summary.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/recurring/application/controllers/recurring_controller.dart";
import "package:ownfinances/features/templates/application/controllers/templates_controller.dart";
import "package:ownfinances/features/templates/domain/entities/transaction_template.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";

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
  int _step = 0;
  bool _isRecurring = false;
  String _recurrenceFrequency = "monthly";
  bool _saveAsTemplate = false;
  final TextEditingController _templateNameController = TextEditingController();
  String _type = "expense";
  String _status = "pending";
  String? _categoryId;
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _date = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaction != null) {
      _date = widget.initialTransaction!.date;
    }
    if (widget.initialTemplate != null) {
      final t = widget.initialTemplate!;
      _type = t.type;
      _amountController.text = t.amount
          .toString(); // formatMoney if needed? No, input expects raw usually? Or formatted.
      _noteController.text = t.note ?? "";
      _categoryId = t.categoryId;
      _fromAccountId = t.fromAccountId;
      _toAccountId = t.toAccountId;
      // We can't set defaults from last transaction if using template
    } else {
      _type = widget.initialType ?? "expense";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final txState = context.read<TransactionsController>().state;
        setState(() {
          _categoryId = txState.lastCategoryId;
          _fromAccountId = txState.lastFromAccountId;
          _toAccountId = txState.lastToAccountId;
        });
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = context.watch<CategoriesController>().state;
    final accountsState = context.watch<AccountsController>().state;
    final reportsState = context.watch<ReportsController>().state;

    final categoryItems = categoriesState.items
        .where((cat) => _type == "transfer" ? false : cat.kind == _type)
        .map((cat) => PickerItem(id: cat.id, label: cat.name))
        .toList();
    final accountItems = accountsState.items
        .map((acc) => PickerItem(id: acc.id, label: acc.name))
        .toList();

    final summary = reportsState.summary;
    final summaryMap = {
      for (final item in summary?.byCategory ?? <CategorySummary>[])
        item.categoryId: item,
    };
    final summaryLine = _categoryId == null ? null : summaryMap[_categoryId];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Row(
              children: [
                PrimaryButton(
                  label: _step == 2 ? "Salvar" : "Avancar",
                  onPressed: _step == 2 ? _save : details.onStepContinue,
                  fullWidth: false,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (_step > 0)
                  SecondaryButton(
                    label: "Voltar",
                    onPressed: details.onStepCancel,
                    fullWidth: false,
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text("Tipo"),
            isActive: _step >= 0,
            content: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _TypeCard(
                  label: "Registrar gasto",
                  selected: _type == "expense",
                  onTap: () => _setType("expense"),
                ),
                _TypeCard(
                  label: "Registrar receita",
                  selected: _type == "income",
                  onTap: () => _setType("income"),
                ),
                _TypeCard(
                  label: "Transferir",
                  selected: _type == "transfer",
                  onTap: () => _setType("transfer"),
                ),
              ],
            ),
          ),
          Step(
            title: const Text("Valor"),
            isActive: _step >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyInput(label: "Valor", controller: _amountController),
                const SizedBox(height: AppSpacing.md),
                if (_type != "income")
                  AccountPicker(
                    label: "Conta de saida",
                    items: accountItems,
                    value: _fromAccountId,
                    onSelected: (item) =>
                        setState(() => _fromAccountId = item.id),
                  ),
                if (_type == "income" || _type == "transfer") ...[
                  const SizedBox(height: AppSpacing.md),
                  AccountPicker(
                    label: "Conta de entrada",
                    items: accountItems,
                    value: _toAccountId,
                    onSelected: (item) =>
                        setState(() => _toAccountId = item.id),
                  ),
                ],
                if (_type != "transfer") ...[
                  const SizedBox(height: AppSpacing.md),
                  CategoryPicker(
                    label: "Categoria",
                    items: categoryItems,
                    value: _categoryId,
                    onSelected: (item) => setState(() => _categoryId = item.id),
                  ),
                ],
              ],
            ),
          ),
          Step(
            title: const Text("Confirmar"),
            isActive: _step >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summaryLine != null)
                  InlineSummaryCard(
                    title: "Categoria selecionada",
                    planned: formatMoney(summaryLine.planned),
                    actual: formatMoney(summaryLine.actual),
                    remaining: formatMoney(summaryLine.remaining),
                  ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Data"),
                  subtitle: Text(formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: "Status"),
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
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text("Repetir (Recorrencia)"),
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v),
                ),
                if (_isRecurring)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: _recurrenceFrequency,
                      items: const [
                        DropdownMenuItem(
                          value: "monthly",
                          child: Text("Mensal"),
                        ),
                        DropdownMenuItem(
                          value: "weekly",
                          child: Text("Semanal"),
                        ),
                        DropdownMenuItem(value: "yearly", child: Text("Anual")),
                      ],
                      onChanged: (v) =>
                          setState(() => _recurrenceFrequency = v!),
                      decoration: const InputDecoration(
                        labelText: "Frequencia",
                      ),
                    ),
                  ),
                SwitchListTile(
                  title: const Text("Salvar como modelo"),
                  value: _saveAsTemplate,
                  onChanged: (v) => setState(() => _saveAsTemplate = v),
                ),
                if (_saveAsTemplate)
                  TextField(
                    controller: _templateNameController,
                    decoration: const InputDecoration(
                      labelText: "Nome do modelo (Ex: Uber Casa)",
                    ),
                  ),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: "Nota (opcional)",
                  ),
                ),
                TextField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: "Tags (separadas por virgula)",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step += 1);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step -= 1);
    }
  }

  void _setType(String type) {
    setState(() {
      _type = type;
      if (type == "transfer") {
        _categoryId = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  Future<void> _save() async {
    final amount = parseMoney(_amountController.text);
    if (amount <= 0) {
      showStandardSnackbar(context, "O valor deve ser maior que 0");
      return;
    }
    if (_type == "transfer") {
      if (_fromAccountId == null || _toAccountId == null) {
        showStandardSnackbar(context, "Falta escolher uma conta");
        return;
      }
    } else {
      if (_categoryId == null) {
        showStandardSnackbar(context, "Falta escolher uma categoria");
        return;
      }
      if (_type == "expense" && _fromAccountId == null) {
        showStandardSnackbar(context, "Falta escolher uma conta");
        return;
      }
      if (_type == "income" && _toAccountId == null) {
        showStandardSnackbar(context, "Falta escolher uma conta");
        return;
      }
    }

    final payload = {
      "type": _type,
      "date": _date.toIso8601String(),
      "amount": amount,
      "categoryId": _type == "transfer" ? null : _categoryId,
      "fromAccountId": _type == "income" ? null : _fromAccountId,
      "toAccountId": _type == "expense" ? null : _toAccountId,
      "note": _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      "tags": _parseTags(_tagsController.text),
      "status": _status,
    };

    if (widget.initialTransaction != null) {
      // It's an update
      if (widget.initialTransaction!.recurringRuleId != null) {
        await _handleRecurringUpdate(payload);
      } else {
        await context.read<TransactionsController>().update(
          widget.initialTransaction!.id,
          payload,
        );
      }
      await context.read<ReportsController>().load();
      if (mounted) {
        showStandardSnackbar(context, "Transacao atualizada");
        context.pop();
      }
      return;
    }

    if (_saveAsTemplate) {
      final templateName = _templateNameController.text.trim();
      if (templateName.isNotEmpty) {
        final templatePayload = {
          "name": templateName,
          "amount": amount,
          "type": _type,
          "currency": "BRL",
          "categoryId": _categoryId,
          "fromAccountId": _fromAccountId,
          "toAccountId": _toAccountId,
          "note": payload["note"],
          "tags": payload["tags"],
        };
        await context.read<TemplatesController>().create(templatePayload);
      }
    }

    if (_isRecurring) {
      // Create Recurring Rule
      final recurringPayload = {
        "frequency": _recurrenceFrequency,
        "interval": 1,
        "startDate": _date.toIso8601String(),
        "active": true,
        "template": {
          "amount": amount,
          "type": _type,
          "currency": "BRL",
          "categoryId": _categoryId,
          "fromAccountId": _fromAccountId,
          "toAccountId": _toAccountId,
          "note": payload["note"],
          "tags": payload["tags"],
        },
      };

      final controller = context.read<RecurringController>();
      final created = await controller.create(recurringPayload);
      if (mounted && created != null) {
        showStandardSnackbar(context, "Regra de recorrencia criada");
        context.go("/transactions");
      } else if (mounted) {
        showStandardSnackbar(
          context,
          controller.state.error ?? "Erro ao criar recorrencia",
        );
      }
      return;
    }

    // Normal Transaction Save
    final controller = context.read<TransactionsController>();
    final created = await controller.create(payload);
    if (!mounted) return;
    if (created == null) {
      showStandardSnackbar(context, "Erro ao salvar");
      return;
    }
    controller.rememberDefaults(created);
    await context.read<ReportsController>().load();
    if (!mounted) return;

    final summary = context.read<ReportsController>().state.summary;
    if (_type == "expense" && _categoryId != null && summary != null) {
      final summaryMap = {
        for (final item in summary.byCategory) item.categoryId: item,
      };
      final line = summaryMap[_categoryId];
      final categoryName = context
          .read<CategoriesController>()
          .state
          .items
          .firstWhere(
            (cat) => cat.id == _categoryId,
            orElse: () => const Category(id: "", name: "", kind: ""),
          )
          .name;
      if (line != null) {
        final remaining = formatMoney(line.remaining);
        final name = categoryName.isEmpty ? "categoria" : categoryName;
        showStandardSnackbar(
          context,
          "Gasto registrado. Restam $remaining em $name este mes.",
        );
      } else {
        showStandardSnackbar(context, "Registrado");
      }
    } else {
      showStandardSnackbar(context, "Registrado");
    }

    if (context.mounted) {
      context.go("/transactions");
    }
  }

  Future<void> _handleRecurringUpdate(Map<String, dynamic> payload) async {
    final mode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar repetición"),
        content: const Text(
          "Esta transacao faz parte de uma serie. Como quer aplicar as mudancas?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, "this"),
            child: const Text("So esta"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, "future"),
            child: const Text("Esta e futuras"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, "all"),
            child: const Text("Todas"),
          ),
        ],
      ),
    );

    if (mode == null) return;

    if (!mounted) return;

    if (mode == "this") {
      await context.read<TransactionsController>().update(
        widget.initialTransaction!.id,
        payload,
      );
    } else if (mode == "future") {
      final ruleId = widget.initialTransaction!.recurringRuleId!;
      final splitDate = DateTime.parse(payload['date']);

      final template = {
        "amount": payload['amount'],
        "type": payload['type'],
        "currency": "BRL",
        "categoryId": payload['categoryId'],
        "fromAccountId": payload['fromAccountId'],
        "toAccountId": payload['toAccountId'],
        "note": payload['note'],
        "tags": payload['tags'],
      };

      await context.read<RecurringController>().split(
        ruleId,
        splitDate,
        template,
      );
      await context.read<TransactionsController>().update(
        widget.initialTransaction!.id,
        payload,
      );
    } else if (mode == "all") {
      showStandardSnackbar(
        context,
        "Editar todas ainda nao implementado. Editando so esta.",
      );
      await context.read<TransactionsController>().update(
        widget.initialTransaction!.id,
        payload,
      );
    }
  }

  List<String>? _parseTags(String raw) {
    final normalized = raw
        .split(",")
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return normalized.isEmpty ? null : normalized;
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.secondary : Colors.black12,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

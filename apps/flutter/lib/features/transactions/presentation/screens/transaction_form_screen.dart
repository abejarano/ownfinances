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

class TransactionFormScreen extends StatefulWidget {
  final String? initialType;

  const TransactionFormScreen({super.key, this.initialType});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  int _step = 0;
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
          onPressed: () => context.go("/transactions"),
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
                  label: _step == 2 ? "Guardar" : "Listo",
                  onPressed: _step == 2 ? _save : details.onStepContinue,
                  fullWidth: false,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (_step > 0)
                  SecondaryButton(
                    label: "Atrás",
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
                  label: "Registrar ingreso",
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
            title: const Text("Monto"),
            isActive: _step >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyInput(label: "Monto", controller: _amountController),
                const SizedBox(height: AppSpacing.md),
                if (_type != "income")
                  AccountPicker(
                    label: "Cuenta de salida",
                    items: accountItems,
                    value: _fromAccountId,
                    onSelected: (item) =>
                        setState(() => _fromAccountId = item.id),
                  ),
                if (_type == "income" || _type == "transfer") ...[
                  const SizedBox(height: AppSpacing.md),
                  AccountPicker(
                    label: "Cuenta de entrada",
                    items: accountItems,
                    value: _toAccountId,
                    onSelected: (item) =>
                        setState(() => _toAccountId = item.id),
                  ),
                ],
                if (_type != "transfer") ...[
                  const SizedBox(height: AppSpacing.md),
                  CategoryPicker(
                    label: "Categoría",
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
                    title: "Categoría seleccionada",
                    planned: formatMoney(summaryLine.planned),
                    actual: formatMoney(summaryLine.actual),
                    remaining: formatMoney(summaryLine.remaining),
                  ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Fecha"),
                  subtitle: Text(formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: "Estado"),
                  items: const [
                    DropdownMenuItem(
                      value: "pending",
                      child: Text("Pendiente"),
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
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: "Nota (opcional)",
                  ),
                ),
                TextField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: "Tags (separadas por coma)",
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
      showStandardSnackbar(context, "El monto debe ser mayor que 0");
      return;
    }
    if (_type == "transfer") {
      if (_fromAccountId == null || _toAccountId == null) {
        showStandardSnackbar(context, "Falta elegir una cuenta");
        return;
      }
    } else {
      if (_categoryId == null) {
        showStandardSnackbar(context, "Falta elegir una categoría");
        return;
      }
      if (_type == "expense" && _fromAccountId == null) {
        showStandardSnackbar(context, "Falta elegir una cuenta");
        return;
      }
      if (_type == "income" && _toAccountId == null) {
        showStandardSnackbar(context, "Falta elegir una cuenta");
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
      CategorySummary? line;
      for (final item in summary.byCategory) {
        if (item.categoryId == _categoryId) {
          line = item;
          break;
        }
      }
      if (line != null) {
        final categories = context.read<CategoriesController>().state.items;
        final categoryMap = {for (final item in categories) item.id: item.name};
        final categoryName = categoryMap[_categoryId];
        showStandardSnackbar(
          context,
          "Gasto registrado. Te quedan ${formatMoney(line.remaining)} en ${categoryName ?? "esta categoría"} este mes.",
        );
      }
    }

    if (context.mounted) {
      context.go("/transactions");
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

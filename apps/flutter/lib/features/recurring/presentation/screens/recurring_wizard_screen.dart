import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/buttons.dart';
import 'package:ownfinances/core/presentation/components/money_input.dart';
import 'package:ownfinances/core/presentation/components/pickers.dart';
import 'package:ownfinances/core/presentation/components/snackbar.dart';
import 'package:ownfinances/core/utils/formatters.dart';
import 'package:ownfinances/features/accounts/application/controllers/accounts_controller.dart';
import 'package:ownfinances/features/categories/application/controllers/categories_controller.dart';
import 'package:ownfinances/features/recurring/application/controllers/recurring_controller.dart';

class RecurringWizardScreen extends StatefulWidget {
  const RecurringWizardScreen({super.key});

  @override
  State<RecurringWizardScreen> createState() => _RecurringWizardScreenState();
}

class _RecurringWizardScreenState extends State<RecurringWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form State
  String _frequency = "monthly";
  int _interval = 1;
  DateTime _startDate = DateTime.now();

  // Template State
  double _amount = 0;
  String _type = "expense";
  String _currency = "BRL";
  String? _categoryId;
  String? _fromAccountId;
  String? _toAccountId;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 1) {
      // Validate Amount
      final val = parseMoney(_amountController.text);
      if (val <= 0) {
        showStandardSnackbar(context, "El monto debe ser mayor que 0");
        return;
      }
      _amount = val;
    }
    if (_currentStep == 2) {
      // Validate Category/Account
      if (_type == "expense" && _fromAccountId == null) {
        showStandardSnackbar(context, "Falta elegir cuenta de salida");
        return;
      }
      if (_type == "income" && _toAccountId == null) {
        showStandardSnackbar(context, "Falta elegir cuenta de entrada");
        return;
      }
      if (_type != "transfer" && _categoryId == null) {
        showStandardSnackbar(context, "Falta elegir categoría");
        return;
      }
    }

    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _finish();
    }
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _finish() async {
    final controller = context.read<RecurringController>();
    final payload = {
      "frequency": _frequency,
      "interval": _interval,
      "startDate": _startDate.toIso8601String(),
      "template": {
        "amount": _amount,
        "type": _type,
        "currency": _currency,
        "categoryId": _categoryId,
        "fromAccountId": _fromAccountId,
        "toAccountId": _toAccountId,
        "note": _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      },
    };

    final created = await controller.create(payload);
    if (created != null && mounted) {
      showStandardSnackbar(context, "Regla creada exitosamente");
      context.pop();
    } else {
      if (mounted) {
        showStandardSnackbar(
          context,
          controller.state.error ?? "Error creando regla",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Recurrencia")),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildStep1(), _buildStep2(), _buildStep3(), _buildStep4()],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: SecondaryButton(label: "Atrás", onPressed: _prevPage),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                label: _currentStep == 3 ? "Crear Rule" : "Siguiente",
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // State
  DateTime? _endDate;

  // ... (previous code)

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Paso 1: Frecuencia",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text("Frecuencia"),
            trailing: DropdownButton<String>(
              value: _frequency,
              items: const [
                DropdownMenuItem(value: "monthly", child: Text("Mensual")),
                DropdownMenuItem(value: "weekly", child: Text("Semanal")),
                DropdownMenuItem(value: "yearly", child: Text("Anual")),
              ],
              onChanged: (v) => setState(() => _frequency = v!),
            ),
          ),
          ListTile(
            title: const Text("Cada (Intervalo)"),
            trailing: DropdownButton<int>(
              value: _interval,
              items: [1, 2, 3, 4, 5, 6, 12]
                  .map((i) => DropdownMenuItem(value: i, child: Text("$i")))
                  .toList(),
              onChanged: (v) => setState(() => _interval = v!),
            ),
          ),
          ListTile(
            title: const Text("Primer Vencimiento"),
            subtitle: Text(formatDate(_startDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (d != null) setState(() => _startDate = d);
            },
          ),
          ListTile(
            title: const Text("Fecha Fin (Opcional)"),
            subtitle: Text(
              _endDate == null ? "Sin límite" : formatDate(_endDate!),
            ),
            trailing: const Icon(Icons.event_busy),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate:
                    _endDate ?? _startDate.add(const Duration(days: 365)),
                firstDate: _startDate,
                lastDate: DateTime(2035),
              );
              if (d != null) setState(() => _endDate = d);
            },
            onLongPress: () => setState(() => _endDate = null),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Paso 2: Monto y Tipo",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: [
              _ChoiceChip(
                label: "Gasto",
                selected: _type == "expense",
                onTap: () => setState(() => _type = "expense"),
              ),
              _ChoiceChip(
                label: "Ingreso",
                selected: _type == "income",
                onTap: () => setState(() => _type = "income"),
              ),
              // Transfer not supported well in simplified wizard yet, stick to expense/income for MVP
              _ChoiceChip(
                label: "Transferencia",
                selected: _type == "transfer",
                onTap: () => setState(() => _type = "transfer"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          MoneyInput(label: "Monto", controller: _amountController),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final categoriesState = context.watch<CategoriesController>().state;
    final accountsState = context.watch<AccountsController>().state;

    final cats = categoriesState.items
        .where((c) => _type == "transfer" ? false : c.kind == _type)
        .map((c) => PickerItem(id: c.id, label: c.name))
        .toList();

    final accs = accountsState.items
        .map((c) => PickerItem(id: c.id, label: c.name))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Paso 3: Detalles",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          if (_type != "income")
            AccountPicker(
              label: "Cuenta de Salida",
              items: accs,
              value: _fromAccountId,
              onSelected: (i) => setState(() => _fromAccountId = i.id),
            ),
          const SizedBox(height: 16),
          if (_type == "income" || _type == "transfer")
            AccountPicker(
              label: "Cuenta de Entrada",
              items: accs,
              value: _toAccountId,
              onSelected: (i) => setState(() => _toAccountId = i.id),
            ),
          const SizedBox(height: 16),
          if (_type != "transfer")
            CategoryPicker(
              label: "Categoría",
              items: cats,
              value: _categoryId,
              onSelected: (i) => setState(() => _categoryId = i.id),
            ),

          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: "Nota (Ej: Alquiler)"),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    // Generate Human Preview
    String frequencyText;
    if (_frequency == 'monthly') {
      frequencyText = "Todo mês, dia ${_startDate.day}";
    } else if (_frequency == 'weekly') {
      // rough mapping
      const weekdays = [
        "",
        "Segunda",
        "Terça",
        "Quarta",
        "Quinta",
        "Sexta",
        "Sábado",
        "Domingo",
      ];
      frequencyText = "Toda semana, ${weekdays[_startDate.weekday]}";
    } else {
      frequencyText = "Anual, em ${formatDate(_startDate)}";
    }

    if (_interval > 1) {
      frequencyText +=
          " (a cada $_interval ${_frequency == 'monthly' ? 'meses' : (_frequency == 'weekly' ? 'semamas' : 'anos')})";
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Confirmar Regla",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "$frequencyText • ${formatMoney(_amount)} • $_type",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),
          _SummaryRow(
            label: "Frecuencia",
            value: "$_frequency (Cada $_interval)",
          ),
          _SummaryRow(label: "Inicio", value: formatDate(_startDate)),
          _SummaryRow(
            label: "Fin",
            value: _endDate == null ? "Indefinido" : formatDate(_endDate!),
          ),
          _SummaryRow(label: "Tipo", value: _type),
          _SummaryRow(label: "Monto", value: formatMoney(_amount)),
          _SummaryRow(label: "Nota", value: _noteController.text),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

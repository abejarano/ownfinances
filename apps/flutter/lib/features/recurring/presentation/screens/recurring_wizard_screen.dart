import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/buttons.dart';
import 'package:ownfinances/core/presentation/components/money_input.dart';
import 'package:ownfinances/core/presentation/components/pickers.dart';
import 'package:ownfinances/core/presentation/components/snackbar.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
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

  // Day of month (1-31)
  int _dayOfMonth = DateTime.now().day;

  // Template State
  double _amount = 0;
  String _type = "expense"; // Default to expense
  String _currency = "BRL";
  String? _categoryId;
  String? _fromAccountId;
  String? _toAccountId; // For Income

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize day to today, or 28 if today > 28 to be safe?
    // Requirement: 1..28 recommended, or explict 29-31 rules.
    // Let's default to today but allow user to pick.
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();

    if (_currentStep == 0) {
      // Step 1: Type & Value
      final val = parseMoney(_amountController.text);
      if (val <= 0) {
        showStandardSnackbar(context, "O valor deve ser maior que 0");
        return;
      }
      _amount = val;
    }

    if (_currentStep == 1) {
      // Step 2: Day, Account, Category
      if (_type == "expense" && _fromAccountId == null) {
        showStandardSnackbar(context, "Falta escolher conta de saída");
        return;
      }
      if (_type == "income" && _toAccountId == null) {
        showStandardSnackbar(context, "Falta escolher conta de entrada");
        return;
      }
      if (_categoryId == null) {
        showStandardSnackbar(context, "Falta escolher categoria");
        return;
      }
    }

    if (_currentStep < 2) {
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

    // Construct Start Date based on Day of Month
    // If today's day > selected day, start next month? Or current month?
    // "Since when?" assumed next cycle or immediately if possible.
    // Let's use logic: Start Date = (Current Year/Month) with selected Day.
    // If that date is in the past, maybe start next month?
    // Actually simplicity: Just set startDate to next occurrence of that day.

    final now = DateTime.now();
    DateTime startDate = DateTime(
      now.year,
      now.month,
      _dayOfMonth > 28 ? 1 : _dayOfMonth,
    ); // Safety for 31s
    // Logic for 29, 30, 31... handled by "closest match" logic if implementation allows.
    // Simple MVP strategy: Find next valid occurrence on or after today.

    DateTime anchorDate = now;
    // Simple loop to find valid anchor
    for (int i = 0; i < 12; i++) {
      final y = anchorDate.year;
      final m = anchorDate.month;
      final lastDay = DateTime(y, m + 1, 0).day;

      // If user wants 31, and this month has 30, we skip this month for anchor?
      // Or we clamp? if we clamp we lose intent. we find a month with that day.
      if (_dayOfMonth <= lastDay) {
        final candidate = DateTime(y, m, _dayOfMonth);
        if (candidate.isAfter(now.subtract(const Duration(days: 1)))) {
          startDate = candidate;
          break;
        }
      }
      // Move to next month
      anchorDate = DateTime(y, m + 1, 1);
    }

    final payload = {
      "frequency": "monthly",
      "interval": 1,
      "startDate": startDate.toIso8601String(),
      "endDate": null, // MVP: No end date
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
      showStandardSnackbar(context, "Regra criada com sucesso");
      context.pop();
    } else {
      if (mounted) {
        showStandardSnackbar(
          context,
          controller.state.error ?? "Erro ao criar regra",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Nova Recorrência"),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildStep1(), _buildStep2(), _buildStep3()],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: SecondaryButton(label: "Voltar", onPressed: _prevPage),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                label: _currentStep == 2 ? "Criar recorrência" : "Próximo",
                onPressed: _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "O que se repete todo mês?",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TypeCard(
                  label: "Despesa",
                  icon: Icons.arrow_downward,
                  color: AppColors.warning, // Expense uses WARNING now
                  selected: _type == "expense",
                  onTap: () {
                    setState(() {
                      _type = "expense";
                      _toAccountId = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TypeCard(
                  label: "Receita",
                  icon: Icons.arrow_upward,
                  color: AppColors.success, // Income uses SUCCESS
                  selected: _type == "income",
                  onTap: () {
                    setState(() {
                      _type = "income";
                      _fromAccountId = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          MoneyInput(label: "Valor", controller: _amountController),
          const SizedBox(height: 8),
          Text(
            "Você poderá ajustar esse valor mês a mês se precisar.",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final categoriesState = context.watch<CategoriesController>().state;
    final accountsState = context.watch<AccountsController>().state;

    final cats = categoriesState.items
        .where((c) => c.kind == _type)
        .map((c) => PickerItem(id: c.id, label: c.name))
        .toList();

    final accs = accountsState.items
        .map((c) => PickerItem(id: c.id, label: c.name))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quando e de onde?",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Day Picker
          Text("Todo mês, dia", style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 31,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = index + 1;
                final isSelected = _dayOfMonth == day;
                return ChoiceChip(
                  label: Text(day.toString()),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _dayOfMonth = day),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface2,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                );
              },
            ),
          ),
          if (_dayOfMonth >= 29)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "⚠️ Em meses sem dia $_dayOfMonth, será usado o último dia.",
                style: const TextStyle(color: AppColors.warning),
              ),
            ),

          const SizedBox(height: 24),

          if (_type == "expense")
            AccountPicker(
              label: "Conta de saída",
              items: accs,
              value: _fromAccountId,
              onSelected: (i) => setState(() => _fromAccountId = i.id),
            ),
          if (_type == "income")
            AccountPicker(
              label: "Conta de entrada",
              items: accs,
              value: _toAccountId,
              onSelected: (i) => setState(() => _toAccountId = i.id),
            ),

          const SizedBox(height: 24),
          CategoryPicker(
            label: "Categoria",
            items: cats,
            value: _categoryId,
            onSelected: (i) => setState(() => _categoryId = i.id),
          ),

          const SizedBox(height: 24),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: "Nota (Opcional, ex: Aluguel)",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Confirmar recorrência",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          Card(
            // Uses default SURFACE-1 from theme
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _SummaryRow(
                    label: "O que",
                    value:
                        "${_type == 'expense' ? 'Despesa' : 'Receita'} de ${formatMoney(_amount)}",
                  ),
                  const Divider(),
                  _SummaryRow(
                    label: "Quando",
                    value:
                        "Todo mês, dia $_dayOfMonth${_dayOfMonth >= 29 ? ' (ou último dia)' : ''}",
                  ),
                  const Divider(),
                  _SummaryRow(
                    label: "Categoria",
                    value: _categoryId == null
                        ? "-"
                        : (context
                              .read<CategoriesController>()
                              .state
                              .items
                              .firstWhere((e) => e.id == _categoryId)
                              .name),
                  ),
                  const Divider(),
                  _SummaryRow(
                    label: "Conta",
                    value:
                        (_type == 'expense' ? _fromAccountId : _toAccountId) ==
                            null
                        ? "-"
                        : (context
                              .read<AccountsController>()
                              .state
                              .items
                              .firstWhere(
                                (e) =>
                                    e.id ==
                                    (_type == 'expense'
                                        ? _fromAccountId
                                        : _toAccountId),
                              )
                              .name),
                  ),
                  if (_noteController.text.isNotEmpty) ...[
                    const Divider(),
                    _SummaryRow(label: "Nota", value: _noteController.text),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Nenhuma transação será criada agora. Você usará o 'Planejar Mês' para gerar os lançamentos.",
            style: TextStyle(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.5)
                : AppColors.borderSoft,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? color.withValues(alpha: 0.15) : AppColors.surface1,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? color : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

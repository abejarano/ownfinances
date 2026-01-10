import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/features/recurring/application/controllers/recurring_controller.dart';
import 'package:ownfinances/features/transactions/application/controllers/transactions_controller.dart';
import 'package:ownfinances/features/reports/application/controllers/reports_controller.dart';
import 'package:intl/intl.dart';

class RecurrencePreviewModal extends StatefulWidget {
  const RecurrencePreviewModal({super.key});

  @override
  State<RecurrencePreviewModal> createState() => _RecurrencePreviewModalState();
}

class _RecurrencePreviewModalState extends State<RecurrencePreviewModal> {
  DateTime _selectedDate = DateTime.now();
  String _selectedOption = 'current'; // 'current', 'next', 'custom'

  @override
  void initState() {
    super.initState();
    // Trigger preview fetch on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreview();
    });
  }

  void _loadPreview() {
    context.read<RecurringController>().preview("monthly", _selectedDate);
  }

  void _selectMonth(String option) {
    setState(() {
      _selectedOption = option;
      if (option == 'current') {
        _selectedDate = DateTime.now();
      } else if (option == 'next') {
        final now = DateTime.now();
        _selectedDate = DateTime(now.year, now.month + 1, 1);
      }
      // For 'custom', keep _selectedDate as is (will be set by date picker)
    });
    _loadPreview();
  }

  Future<void> _pickCustomMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedOption = 'custom';
        _selectedDate = DateTime(picked.year, picked.month, 1);
      });
      _loadPreview();
    }
  }

  String _getMonthLabel() {
    final formatter = DateFormat('MMMM yyyy', 'pt_BR');
    return formatter.format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecurringController>().state;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 600,
      child: Column(
        children: [
          Text(
            "Gerar recorrências - ${_getMonthLabel()}",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // Month selector
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text("Este mês"),
                  selected: _selectedOption == 'current',
                  onSelected: (selected) {
                    if (selected) _selectMonth('current');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text("Próximo mês"),
                  selected: _selectedOption == 'next',
                  onSelected: (selected) {
                    if (selected) _selectMonth('next');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickCustomMonth,
                  child: const Text("Escolher mês"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.previewItems.isEmpty)
            const Expanded(
              child: Center(
                child: Text("Não há nada pendente para este mês."),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: state.previewItems.length,
                itemBuilder: (context, index) {
                  final item = state.previewItems[index];
                  final isNew = item.status == 'new';
                  return ListTile(
                    title: Text(item.template.note ?? "Sem nota"),
                    subtitle: Text(
                      "${DateFormat('dd/MM/yyyy').format(item.date)} - ${isNew ? 'Nova' : 'Já gerada'}",
                    ),
                    trailing: Text(
                      "${item.template.currency} ${item.template.amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isNew ? Colors.green : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: state.previewItems.isEmpty
                ? null
                : () async {
                    final newCount = state.previewItems
                        .where((item) => item.status == 'new')
                        .length;
                    
                    await context.read<RecurringController>().run(
                      "monthly",
                      _selectedDate,
                    );
                    await context.read<TransactionsController>().load();
                    await context.read<ReportsController>().load();
                    
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Recorrências geradas: $newCount"),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
            child: const Text("Gerar tudo"),
          ),
        ],
      ),
    );
  }
}

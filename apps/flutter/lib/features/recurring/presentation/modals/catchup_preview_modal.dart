import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/features/recurring/application/controllers/recurring_controller.dart';
import 'package:ownfinances/features/transactions/application/controllers/transactions_controller.dart';
import 'package:ownfinances/features/reports/application/controllers/reports_controller.dart';
import 'package:intl/intl.dart';

class CatchupPreviewModal extends StatefulWidget {
  final List<Map<String, dynamic>> months;

  const CatchupPreviewModal({super.key, required this.months});

  @override
  State<CatchupPreviewModal> createState() => _CatchupPreviewModalState();
}

class _CatchupPreviewModalState extends State<CatchupPreviewModal> {
  final Set<String> _selectedMonths = {};
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Select all by default
    _selectedMonths.addAll(
      widget.months.map((m) => m['month'] as String),
    );
  }

  String _formatMonth(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return DateFormat('MMMM yyyy', 'pt_BR').format(date);
    } catch (e) {
      return monthStr;
    }
  }

  Future<void> _generateSelected() async {
    if (_selectedMonths.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    int totalGenerated = 0;

    try {
      final controller = context.read<RecurringController>();

      // Generate for each selected month
      for (final monthStr in _selectedMonths) {
        final parts = monthStr.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final date = DateTime(year, month, 1);

        final result = await controller.run("monthly", date);
        totalGenerated += result?['generated'] as int? ?? 0;
      }

      // Refresh other controllers
      await context.read<TransactionsController>().load();
      await context.read<ReportsController>().load();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Geradas $totalGenerated recorrências de ${_selectedMonths.length} ${_selectedMonths.length == 1 ? 'mês' : 'meses'}",
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao gerar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSelected = widget.months
        .where((m) => _selectedMonths.contains(m['month']))
        .fold<int>(0, (sum, m) => sum + (m['count'] as int? ?? 0));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      height: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Gerar meses passados",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Selecione os meses que deseja gerar:",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          // Select/Deselect all
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMonths.clear();
                  });
                },
                child: const Text("Desmarcar todos"),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMonths.clear();
                    _selectedMonths.addAll(
                      widget.months.map((m) => m['month'] as String),
                    );
                  });
                },
                child: const Text("Marcar todos"),
              ),
            ],
          ),
          const Divider(),
          // Months list
          Expanded(
            child: ListView.builder(
              itemCount: widget.months.length,
              itemBuilder: (context, index) {
                final month = widget.months[index];
                final monthStr = month['month'] as String;
                final count = month['count'] as int? ?? 0;
                final isSelected = _selectedMonths.contains(monthStr);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: _isGenerating
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedMonths.add(monthStr);
                            } else {
                              _selectedMonths.remove(monthStr);
                            }
                          });
                        },
                  title: Text(_formatMonth(monthStr)),
                  subtitle: Text("$count lançamento${count == 1 ? '' : 's'}"),
                  secondary: Icon(
                    Icons.calendar_month,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // Summary and action
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              "Total selecionado: $totalSelected lançamento${totalSelected == 1 ? '' : 's'} de ${_selectedMonths.length} ${_selectedMonths.length == 1 ? 'mês' : 'meses'}",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton(
            onPressed: _isGenerating || _selectedMonths.isEmpty
                ? null
                : _generateSelected,
            child: _isGenerating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Gerar selecionados"),
          ),
        ],
      ),
    );
  }
}

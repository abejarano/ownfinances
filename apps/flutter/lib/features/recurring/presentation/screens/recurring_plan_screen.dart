import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/buttons.dart';
import 'package:ownfinances/core/presentation/components/snackbar.dart';
import 'package:ownfinances/core/utils/formatters.dart';
import 'package:ownfinances/features/recurring/application/controllers/recurring_controller.dart';
import 'package:ownfinances/features/recurring/domain/entities/recurring_rule.dart';
import 'package:ownfinances/features/categories/application/controllers/categories_controller.dart';

import 'package:ownfinances/core/presentation/components/month_picker_dialog.dart';

class RecurringPlanScreen extends StatefulWidget {
  const RecurringPlanScreen({super.key});

  @override
  State<RecurringPlanScreen> createState() => _RecurringPlanScreenState();
}

class _RecurringPlanScreenState extends State<RecurringPlanScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreview();
    });
  }

  void _loadPreview() {
    context.read<RecurringController>().preview('monthly', _selectedDate);
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
      );
    });
    _loadPreview();
  }

  Future<void> _pickMonth() async {
    final d = await showDialog<DateTime>(
      context: context,
      builder: (context) => MonthPickerDialog(
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      ),
    );

    if (d != null) {
      setState(() {
        _selectedDate = DateTime(d.year, d.month);
      });
      _loadPreview();
    }
  }

  Future<void> _ignore(String ruleId) async {
    await context.read<RecurringController>().ignore(ruleId, _selectedDate);
  }

  Future<void> _undoIgnore(String ruleId) async {
    await context.read<RecurringController>().undoIgnore(ruleId, _selectedDate);
  }

  Future<void> _run() async {
    final controller = context.read<RecurringController>();
    final result = await controller.run('monthly', _selectedDate);

    if (result != null && mounted) {
      final count = result['generated'] ?? 0;
      showStandardSnackbar(context, "Gerados $count lançamentos!");

      // Navigate to pending or refresh?
      // Requirement: Optional "Ir para confirmar" -> pending transactions
      if (count > 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Lançamentos gerados"),
            content: Text("$count lançamentos foram criados como pendentes."),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text("Ficar aqui"),
              ),
              TextButton(
                onPressed: () {
                  context.pop(); // close dialog
                  context.push('/transacoes/pendentes'); // Assumed route
                },
                child: const Text("Ir para confirmar"),
              ),
            ],
          ),
        );
      }

      // Refresh preview to update status to "already_generated"
      _loadPreview();
    } else {
      if (mounted) {
        showStandardSnackbar(
          context,
          controller.state.error ?? "Erro ao gerar",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecurringController>().state;
    final loading = state.isLoading;
    final items = state.previewItems;

    // Calc summary
    final toGenerate = items.where((i) => i.status == 'new').length;
    final generated = items
        .where((i) => i.status == 'already_generated')
        .length;
    final ignored = items.where((i) => i.status == 'ignored').length;

    // Group items by status for clearer UI? Or just list by date.
    // List by date is better for "Planner".
    // Sort by date
    // Note: API returns array, maybe unsorted.
    // Let's sort locally if needed, but assuming API order (by rule start date usually but here instance date).

    return Scaffold(
      appBar: AppBar(
        title: const Text("Planejar Mês"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickMonth,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildSummary(toGenerate, generated, ignored),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? const Center(
                    child: Text("Nenhuma recorrência prevista para este mês."),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildPreviewItem(item);
                    },
                  ),
          ),
          if (!loading && items.isNotEmpty && toGenerate > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PrimaryButton(
                label: "Gerar lançamentos ($toGenerate)",
                onPressed: _run,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            "${formatMonthYear(_selectedDate)}", // helper format e.g. "Janeiro 2026"
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  String formatMonthYear(DateTime d) {
    // Quick formatter
    const months = [
      "Jan",
      "Fev",
      "Mar",
      "Abr",
      "Mai",
      "Jun",
      "Jul",
      "Ago",
      "Set",
      "Out",
      "Nov",
      "Dez",
    ];
    return "${months[d.month - 1]} ${d.year}";
  }

  Widget _buildSummary(int toGen, int gen, int ign) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryBadge(count: toGenerateBadge(toGen), label: "A gerar"),
          _SummaryBadge(count: "$gen", label: "Gerados", color: Colors.green),
          _SummaryBadge(count: "$ign", label: "Ignorados", color: Colors.grey),
        ],
      ),
    );
  }

  String toGenerateBadge(int c) => "$c";

  String _resolveDescription(RecurringTemplate template) {
    if (template.note != null && template.note!.trim().isNotEmpty) {
      return template.note!;
    }

    if (template.categoryId != null) {
      final cats = context.read<CategoriesController>().state.items;
      final cat = cats.where((c) => c.id == template.categoryId).firstOrNull;
      if (cat != null) {
        return cat.name;
      }
    }

    // Fallback: Try Accounts?
    // Usually category is the best descriptor.
    // If not, "Receita" or "Despesa" + amount?
    // Or just "Sem descrição" but let's try to be helpful.
    return "Sem descrição";
  }

  Widget _buildPreviewItem(RecurringPreviewItem item) {
    final isIgnored = item.status == 'ignored';
    final isGenerated = item.status == 'already_generated';
    final isNew = item.status == 'new';

    // Check if day matches rule or is "end of month" adjustment
    // The API returns the calculated date. If it's e.g. Feb 28, but rule is 31, user might want to know.
    // The API doesn't return the rule's original day in PreviewItem (only template).
    // We can infer or just show the actual date. Showing actual date is best.

    final description = _resolveDescription(item.template);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isIgnored ? Colors.grey.shade100 : null,
      child: ListTile(
        leading: Icon(
          item.template.type == 'expense'
              ? Icons.arrow_downward
              : Icons.arrow_upward,
          color: isIgnored
              ? Colors.grey
              : (item.template.type == 'expense' ? Colors.red : Colors.green),
        ),
        title: Text(
          description,
          style: TextStyle(
            decoration: isIgnored ? TextDecoration.lineThrough : null,
            color: isIgnored ? Colors.grey : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "${item.date.day}/${item.date.month} • ${formatMoney(item.template.amount)}",
          style: TextStyle(color: isIgnored ? Colors.grey : null),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGenerated)
              const Chip(
                label: Text("Gerado"),
                backgroundColor: Colors.greenAccent,
                visualDensity: VisualDensity.compact,
              ),
            if (isIgnored)
              IconButton(
                icon: const Icon(
                  Icons.unpublished_outlined,
                  color: Colors.grey,
                ), // Unchecked box metaphor
                tooltip: "Restaurar (Incluir na geração)",
                onPressed: () => _undoIgnore(item.recurringRuleId),
              ),
            if (isNew)
              IconButton(
                icon: const Icon(
                  Icons.check_box,
                  color: Colors.blue,
                ), // Checked box metaphor
                tooltip: "Ignorar (Não gerar)",
                onPressed: () => _ignore(item.recurringRuleId),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String count;
  final String label;
  final Color? color;
  const _SummaryBadge({required this.count, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

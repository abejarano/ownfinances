import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/cards.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/features/recurring/application/controllers/recurring_controller.dart';
import 'package:intl/intl.dart';

class RecurrenceSummaryCard extends StatefulWidget {
  const RecurrenceSummaryCard({super.key});

  @override
  State<RecurrenceSummaryCard> createState() => _RecurrenceSummaryCardState();
}

class _RecurrenceSummaryCardState extends State<RecurrenceSummaryCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecurringController>().loadPendingSummary();
    });
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecurringController>().state;

    if (state.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final count = state.toGenerateCount;
    final monthLabel = state.currentMonth.isNotEmpty
        ? _formatMonth(state.currentMonth)
        : 'este mês';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recorrências deste mês",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (count == 0)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "Tudo pronto ✅",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else
              Text(
                "Você tem $count lançamento${count > 1 ? 's' : ''} para gerar ($monthLabel)",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/recurring/plan');
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text("Planejar mês"),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () {
                    context.push('/transactions/pending');
                  },
                  child: const Text("Ver detalhes"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

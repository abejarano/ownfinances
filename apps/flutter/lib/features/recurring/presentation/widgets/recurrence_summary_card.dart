import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/features/recurring/application/controllers/recurring_controller.dart';
import 'package:ownfinances/features/transactions/application/controllers/pending_transactions_controller.dart';
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
      final controller = context.read<RecurringController>();
      controller.loadPendingSummary();
      controller.load(); // Load rules to check if any exist
      context.read<PendingTransactionsController>().loadPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recurrenceState = context.watch<RecurringController>().state;
    final pendingState = context.watch<PendingTransactionsController>().state;

    if (recurrenceState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final toGenerateCount = recurrenceState.toGenerateCount;
    final hasRules = recurrenceState.items.isNotEmpty;
    final pendingCount = pendingState.items.length;

    // Determine State
    // State A: To Generate
    if (toGenerateCount > 0) {
      return _buildStateA(context, toGenerateCount, pendingCount);
    }

    // State C: No Rules (and thus no generation needed)
    if (!hasRules) {
      return _buildStateC(context);
    }

    // State B: All Done (Rules exist but nothing to generate)
    return _buildStateB(context);
  }

  Widget _buildStateA(BuildContext context, int count, int pendingCount) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Faltam $count lançamentos para gerar",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/recurring/plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Planejar mês"),
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/transactions/pending'),
                    child: const Text("Ver pendentes"),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateB(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Tudo pronto ✅",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/recurring'),
              child: const Text("Ver regras"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateC(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Você ainda não tem recorrências",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Criar primeira"),
              onPressed: () => context.push('/recurring/new'),
            ),
          ],
        ),
      ),
    );
  }
}

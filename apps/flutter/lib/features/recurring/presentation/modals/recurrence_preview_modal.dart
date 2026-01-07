import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/features/recurring/application/controllers/recurring_controller.dart';
import 'package:ownfinances/features/transactions/application/controllers/transactions_controller.dart';
import 'package:ownfinances/features/reports/application/controllers/reports_controller.dart';

class RecurrencePreviewModal extends StatefulWidget {
  const RecurrencePreviewModal({super.key});

  @override
  State<RecurrencePreviewModal> createState() => _RecurrencePreviewModalState();
}

class _RecurrencePreviewModalState extends State<RecurrencePreviewModal> {
  @override
  void initState() {
    super.initState();
    // Trigger preview fetch on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecurringController>().preview("monthly", DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecurringController>().state;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 500,
      child: Column(
        children: [
          Text(
            "Gerar recorrencias",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (state.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.previewItems.isEmpty)
            const Expanded(
              child: Center(
                child: Text("Nao ha nada pendente para este mes."),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: state.previewItems.length,
                itemBuilder: (context, index) {
                  final item = state.previewItems[index];
                  return ListTile(
                    title: Text(item.template.note ?? "Sem nota"),
                    subtitle: Text(
                      "${item.date.toIso8601String()} - ${item.status}",
                    ),
                    trailing: Text(
                      "${item.template.currency} ${item.template.amount}",
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
                    await context.read<RecurringController>().run(
                      "monthly",
                      DateTime.now(),
                    );
                    await context.read<TransactionsController>().load();
                    await context.read<ReportsController>().load();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            child: const Text("Gerar tudo"),
          ),
        ],
      ),
    );
  }
}

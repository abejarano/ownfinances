import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/features/recurring/application/controllers/recurring_controller.dart';

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
            "Generar Recurrencias",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (state.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.previewItems.isEmpty)
            const Expanded(
              child: Center(
                child: Text("No hay nada pendiente para este mes."),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: state.previewItems.length,
                itemBuilder: (context, index) {
                  final item = state.previewItems[index];
                  return ListTile(
                    title: Text(item.template.note ?? "Sin nota"),
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
                : () {
                    context.read<RecurringController>().run(
                      "monthly",
                      DateTime.now(),
                    );
                  },
            child: const Text("Generar Todo"),
          ),
        ],
      ),
    );
  }
}

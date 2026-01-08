import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/buttons.dart';
import 'package:ownfinances/core/presentation/components/snackbar.dart';
import 'package:ownfinances/features/templates/application/controllers/templates_controller.dart';
import 'package:ownfinances/features/transactions/application/controllers/transactions_controller.dart';
import 'package:ownfinances/features/reports/application/controllers/reports_controller.dart';

class TemplateListScreen extends StatelessWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TemplatesController>().state;

    return Scaffold(
      appBar: AppBar(title: const Text("Plantillas")),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No tienes plantillas guardadas."),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    label: "Crear una nueva",
                    onPressed: () => context.go(
                      "/transactions/new",
                    ), // Or dedicated create screen
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(item.name[0].toUpperCase()),
                    ),
                    title: Text(item.name),
                    subtitle: Text("${item.currency} ${item.amount}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "Registrar agora",
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () async {
                            final reports = context.read<ReportsController>();
                            final period = reports.state.period;
                            final payload = {
                              "type": item.type,
                              "date": DateTime.now().toIso8601String(),
                              "amount": item.amount,
                              "currency": item.currency,
                              "categoryId": item.categoryId,
                              "fromAccountId": item.fromAccountId,
                              "toAccountId": item.toAccountId,
                              "note": item.note,
                              "tags": item.tags,
                              "status": "pending",
                            };

                            final created = await context
                                .read<TransactionsController>()
                                .createWithImpact(
                                  payload: payload,
                                  period: period,
                                );
                            if (created?.impact != null) {
                              reports.applyImpactFromJson(created!.impact!);
                            } else {
                              await reports.load();
                            }
                            if (context.mounted) {
                              showStandardSnackbar(context, "Registrado");
                            }
                          },
                        ),
                        IconButton(
                          tooltip: "Editar antes",
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            context.push("/transactions/new", extra: item);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/buttons.dart';
import 'package:ownfinances/features/templates/application/controllers/templates_controller.dart';

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
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to Transaction Form pre-filled
                      context.push(
                        "/transactions/new",
                        extra: item, // Pass the template object
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

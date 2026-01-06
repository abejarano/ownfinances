import "package:flutter/material.dart";
import "package:ownfinances/ui/components/buttons.dart";
import "package:ownfinances/ui/theme/app_theme.dart";

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Transacciones", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: const [
              Chip(label: Text("Fecha")),
              Chip(label: Text("Cuenta")),
              Chip(label: Text("Categoría")),
              Chip(label: Text("Estado")),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("Cafetería #$index"),
                  subtitle: const Text("Pendiente • 12/01/2026"),
                  trailing: const Text("- R$ 18,50"),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: "Registrar gasto", onPressed: () {}),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(label: "Registrar ingreso", onPressed: () {}),
        ],
      ),
    );
  }
}

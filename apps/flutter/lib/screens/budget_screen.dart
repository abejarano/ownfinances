import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/cards.dart";
import "package:ownfinances/core/theme/app_theme.dart";

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text("Presupuesto", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        const InlineSummaryCard(
          title: "Plan del mes",
          planned: "R\$ 4.000,00",
          actual: "R\$ 2.740,00",
          remaining: "R\$ 1.260,00",
        ),
        const SizedBox(height: AppSpacing.lg),
        ...List.generate(
          4,
          (index) => ListTile(
            title: Text("Categoria ${index + 1}"),
            subtitle: const Text("Planificado R\$ 500,00"),
            trailing: const Text("Actual R\$ 320,00"),
          ),
        ),
      ],
    );
  }
}

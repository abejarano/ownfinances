import "package:flutter/material.dart";
import "package:ownfinances/ui/components/cards.dart";
import "package:ownfinances/ui/theme/app_theme.dart";

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          "Resumo do mês",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        const InlineSummaryCard(
          title: "Janeiro 2026",
          planned: "R$ 3.500,00",
          actual: "R$ 2.740,00",
          remaining: "R$ 760,00",
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          "Ações rápidas",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickActionCard(
          icon: Icons.arrow_downward,
          title: "Registrar gasto",
          subtitle: "Salió R$ 0,00",
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickActionCard(
          icon: Icons.arrow_upward,
          title: "Registrar ingreso",
          subtitle: "Entró R$ 0,00",
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickActionCard(
          icon: Icons.compare_arrows,
          title: "Transferir",
          subtitle: "Mover entre cuentas",
          onTap: () {},
        ),
      ],
    );
  }
}

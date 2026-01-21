import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/recurring/presentation/widgets/recurrence_summary_card.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_month_summary_card.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_debts_card.dart";

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportsState = context.watch<ReportsController>().state;
    final categories = context.watch<CategoriesController>().state.items;
    final summary = reportsState.summary;
    final periodLabel = formatMonth(reportsState.date);

    // Alerts Logic
    final overspent = summary?.overspentCategories ?? [];
    final categoryMap = {for (final cat in categories) cat.id: cat.name};
    final List<Widget> alerts = [];

    // Alert 1: Overspent
    if (overspent.isNotEmpty) {
      final firstName =
          categoryMap[overspent.first] ?? "Categoria desconhecida";
      final count = overspent.length;
      final text = count > 1
          ? "Estourou $count categorias"
          : "Estourou $firstName";
      alerts.add(
        _AlertCard(text: text, icon: Icons.error_outline, color: Colors.red),
      );
    }

    // Alert 2: Deficit (Example logic, can be refined)
    if ((summary?.totals.actualNet ?? 0) < 0 &&
        (summary?.totals.remainingExpense ?? 0) <= 0) {
      alerts.add(
        const _AlertCard(
          text: "Você fechou o mês no vermelho",
          icon: Icons.trending_down,
          color: Colors.orange,
        ),
      );
    }

    // Limit to 2 alerts
    final displayAlerts = alerts.take(2).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // 1. Month Summary
        Text("Resumo do mês", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        DashboardMonthSummaryCard(
          summary: summary,
          periodLabel: periodLabel,
          onTap: () => context.go(
            "/reports",
          ), // Or /budget, keeping consistent with old which was /budget? Old was /budget. Let's send to Reports or Budget? Budget seems more detailed.
        ),

        // 2. Alerts (if any)
        if (displayAlerts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ...displayAlerts.map(
            (a) => Padding(padding: const EdgeInsets.only(bottom: 8), child: a),
          ),
        ],

        // 3. Debts
        const SizedBox(height: AppSpacing.md),
        const DashboardDebtsCard(),

        // 4. Recurrence Summary
        const SizedBox(height: AppSpacing.md),
        const RecurrenceSummaryCard(),

        // 5. Quick Actions
        const SizedBox(height: AppSpacing.lg),
        Text("Ações rápidas", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.arrow_downward,
                label: "Gasto",
                color: Colors.red,
                onTap: () => context.push("/transactions/new?type=expense"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.arrow_upward,
                label: "Receita",
                color: Colors.green,
                onTap: () => context.push("/transactions/new?type=income"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.compare_arrows,
                label: "Transferir",
                color: Colors.blue,
                onTap: () => context.push("/transactions/new?type=transfer"),
              ),
            ),
          ],
        ),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _AlertCard({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(color: color.withOpacity(0.3)), // Removed border per PO
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

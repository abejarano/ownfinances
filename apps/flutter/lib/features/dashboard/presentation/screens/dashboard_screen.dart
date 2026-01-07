import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/cards.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/recurring/presentation/modals/recurrence_preview_modal.dart";

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportsState = context.watch<ReportsController>().state;
    final categories = context.watch<CategoriesController>().state.items;
    final summary = reportsState.summary;
    final periodLabel = formatMonth(reportsState.date);

    final overspent = summary?.overspentCategories ?? [];
    final categoryMap = {for (final cat in categories) cat.id: cat.name};
    final overspentName = overspent.isEmpty
        ? null
        : categoryMap[overspent.first];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text("Resumo do mes", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        InlineSummaryCard(
          title: periodLabel,
          planned: formatMoney(summary?.totals.plannedExpense ?? 0),
          actual: formatMoney(summary?.totals.actualExpense ?? 0),
          remaining: formatMoney(summary?.totals.remainingExpense ?? 0),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "Neto planejado: ${formatMoney(summary?.totals.plannedNet ?? 0)} • Neto real: ${formatMoney(summary?.totals.actualNet ?? 0)}",
          style: TextStyle(
            color:
                (summary?.totals.actualNet ?? 0) < 0 ? Colors.redAccent : Colors.greenAccent,
          ),
        ),
        if (overspent.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            overspentName == null
                ? "Estourou ${overspent.length} categorias"
                : "Estourou $overspentName",
            style: const TextStyle(color: AppColors.accent),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: "Ver detalhes",
          onPressed: () => context.go("/budget"),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          "Acoes rapidas",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickActionCard(
          icon: Icons.arrow_downward,
          title: "Registrar gasto",
          subtitle: "Saiu ${formatMoney(summary?.totals.actualExpense ?? 0)}",
          onTap: () => context.push("/transactions/new?type=expense"),
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickActionCard(
          icon: Icons.arrow_upward,
          title: "Registrar receita",
          subtitle: "Entrou ${formatMoney(summary?.totals.actualIncome ?? 0)}",
          onTap: () => context.push("/transactions/new?type=income"),
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickActionCard(
          icon: Icons.compare_arrows,
          title: "Transferir",
          subtitle: "Mover entre contas",
          onTap: () => context.push("/transactions/new?type=transfer"),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text("Recorrencias", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        QuickActionCard(
          icon: Icons.calendar_today,
          title: "Gerar gastos do mes",
          subtitle: "Processar pendentes",
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const RecurrencePreviewModal(),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        QuickActionCard(
          icon: Icons.add,
          title: "Criar regra",
          subtitle: "Programar gasto/receita",
          onTap: () => context.push("/recurring/new"),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text("Gestao", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: "Dividas",
          onPressed: () => context.go("/debts"),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: "Metas",
          onPressed: () => context.go("/goals"),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: "Categorias",
          onPressed: () => context.go("/categories"),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: "Contas",
          onPressed: () => context.go("/accounts"),
        ),
      ],
    );
  }
}

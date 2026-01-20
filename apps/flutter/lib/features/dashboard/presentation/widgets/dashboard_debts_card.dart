import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/features/debts/application/controllers/debts_controller.dart';
import 'package:ownfinances/features/debts/domain/entities/debt_overview.dart';

class DashboardDebtsCard extends StatefulWidget {
  const DashboardDebtsCard({super.key});

  @override
  State<DashboardDebtsCard> createState() => _DashboardDebtsCardState();
}

class _DashboardDebtsCardState extends State<DashboardDebtsCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtsController>().loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DebtsController>().state;

    // Loading state
    if (state.isLoadingOverview) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final overview = state.overview;

    // State 2: No active debts
    // If overview is null or counts.activeDebts == 0
    if (overview == null || overview.counts.activeDebts == 0) {
      return _buildEmptyState(context);
    }

    // State 3: Active debts but everything paid off (totalAmountDue == 0)
    if (overview.totalAmountDue == 0) {
      return _buildAllGoodState(context, overview);
    }

    // State 1: Active debts with amount due
    return _buildActiveState(context, overview);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              "Você ainda não cadastrou dívidas.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.push("/debts"),
              child: const Text("Adicionar dívida"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllGoodState(BuildContext context, DebtOverview overview) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "Em dia", // Subtexto "✅" adicionado visualmente pelo ícone ou unicode se preferir
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Optional Credit Balance? PO said optional. Usually creditBalance is part of summary logic.
            // Overview model doesn't explicitly return creditBalance aggregates, only totalAmountDue.
            // If needed, backend should provide it. Plan didn't strictly mandate it. Skipping for now.
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.push("/debts"),
              child: const Text("Ver dívidas"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveState(BuildContext context, DebtOverview overview) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final nextDue = overview.nextDue;
    final isOverdue = nextDue?.isOverdue ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Dívidas", style: Theme.of(context).textTheme.titleSmall),
                TextButton(
                  onPressed: () => context.push("/debts"),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("Ver dívidas"),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Metrics
            _MetricRow(
              label: "Total a pagar",
              value: currencyFormat.format(overview.totalAmountDue),
              isBold: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricRow(
              label: "Pago este mês",
              value: currencyFormat.format(overview.totalPaidThisMonth),
              color: Colors.grey,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // Next Due
            if (nextDue != null) ...[
              Row(
                children: [
                  Icon(
                    isOverdue ? Icons.error_outline : Icons.calendar_today,
                    size: 16,
                    color: isOverdue ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: isOverdue ? "Vencido: " : "Próximo: ",
                            style: TextStyle(
                              color: isOverdue ? Colors.red : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                "${DateFormat('dd/MM').format(nextDue.date)} — ${nextDue.name}",
                          ),
                        ],
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Secondary CTA
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                // TODO: Implement bottom sheet logic for payment
                onPressed: () => context.push("/debts"),
                child: const Text("Registrar pagamento"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _MetricRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

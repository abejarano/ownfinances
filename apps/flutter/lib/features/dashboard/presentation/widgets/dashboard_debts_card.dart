import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/core/presentation/components/money_text.dart';
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Em dia",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
            // Metrics
            _MetricRow(
              label: "Total a pagar",
              child: MoneyText(
                value: overview.totalAmountDue,
                variant: MoneyTextVariant.l,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _MetricRow(
              label: "Pago este mês",
              child: MoneyText(
                value: overview.totalPaidThisMonth,
                variant: MoneyTextVariant.m,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // Next Due
            if (nextDue != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isOverdue
                        ? AppColors.danger
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: isOverdue ? "Vencido: " : "Próximo: ",
                            style: TextStyle(
                              color: isOverdue
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                "${DateFormat('dd/MM').format(nextDue.date)} — ${nextDue.name}",
                            style: TextStyle(
                              // Explicitly handle overdue coloring per PO request for date/name?
                              // "date: TEXT-primary... normal: TEXT-primary"
                              // Only "Vencido" logic applies specific colors.
                              // If overdue: "si vencido: DANGER"
                              color: isOverdue
                                  ? AppColors.danger
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (isOverdue) ...[
                            TextSpan(
                              text: " (Venceu!)",
                              style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
              child: ElevatedButton(
                // Use ElevatedButton for Primary action "Registrar pagamento"
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
  final Widget child;

  const _MetricRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
        ),
        child,
      ],
    );
  }
}

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/dashboard/application/controllers/dashboard_controller.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_accounts_carousel.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_other_currencies_card.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_debts_card.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_quick_actions.dart";
import "package:ownfinances/features/recurring/presentation/widgets/recurrence_summary_card.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_filters.dart";

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We now watch DashboardController instead of ReportsController for the main logic
    final controller = context.watch<DashboardController>();
    final state = controller.state;

    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      backgroundColor: AppColors.surface1,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          // 1. Month Summary Quick Link (Before Carousel)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: OutlinedButton.icon(
              onPressed: () => context.push("/month-summary"),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text("Resumo do Mês por Categorias"),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),

          // 2. Accounts Carousel (Per Account)
          const SizedBox(height: AppSpacing.md),
          DashboardAccountsCarousel(
            summaries: state.accountSummaries,
            onTap: (accountId) {
              // Navigate to transactions filtered by account and month
              final start = DateTime(state.date.year, state.date.month, 1);
              final end = DateTime(
                state.date.year,
                state.date.month + 1,
                0,
                23,
                59,
                59,
              );

              context.read<TransactionsController>().setFilters(
                TransactionFilters(
                  dateFrom: start,
                  dateTo: end,
                  accountId: accountId,
                ),
              );
              // Switch to transactions tab
              context.go("/transactions");
            },
          ),

          // 3. Other Currencies (Compact)
          if (state.otherCurrencies.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            DashboardOtherCurrenciesCard(
              otherCurrencies: state.otherCurrencies,
            ),
          ],

          // 4. Debts (Keep as is)
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [DashboardDebtsCard()],
            ),
          ),

          // 5. Recurrence Summary (Keep as is)
          const SizedBox(height: AppSpacing.md),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: RecurrenceSummaryCard(),
          ),

          // 6. Quick Actions
          const SizedBox(height: AppSpacing.lg),
          const DashboardQuickActions(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

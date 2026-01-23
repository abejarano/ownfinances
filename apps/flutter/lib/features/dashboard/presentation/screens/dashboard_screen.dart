import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/dashboard/application/controllers/dashboard_controller.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_month_summary_card.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_accounts_carousel.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_other_currencies_card.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_debts_card.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_quick_actions.dart";
import "package:ownfinances/features/recurring/presentation/widgets/recurrence_summary_card.dart";

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We now watch DashboardController instead of ReportsController for the main logic
    final controller = context.watch<DashboardController>();
    final state = controller.state;

    final periodLabel = formatMonth(state.date);

    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      backgroundColor: AppColors.surface1,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          // 1. Month Summary (BRL Only)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DashboardMonthSummaryCard(
              state: state,
              periodLabel: periodLabel,
              onTap: () {
                // Filter transactions for BRL?
                // Default behavior: go to transactions list.
                context.go("/transactions");
              },
            ),
          ),

          // 2. Accounts Carousel (Per Account)
          const SizedBox(height: AppSpacing.md),
          DashboardAccountsCarousel(
            summaries: state.accountSummaries,
            onTap: (accountId) {
              // Navigate to transactions filtered by account and month
              final start = DateTime(state.date.year, state.date.month, 1);
              final end = DateTime(state.date.year, state.date.month + 1, 0);

              final dateFrom = start.toIso8601String();
              final dateTo = end.toIso8601String();

              context.push(
                Uri(
                  path: "/transactions",
                  queryParameters: {
                    "accountId": accountId,
                    // We might need to handle date passing to TransactionsScreen if it supports query params init
                    // Assuming TransactionsScreen might need update to read params or we rely on filter store?
                    // Usually standard practice:
                    "dateFrom": dateFrom,
                    "dateTo": dateTo,
                  },
                ).toString(),
              );
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

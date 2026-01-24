import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/dashboard/application/controllers/dashboard_controller.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_shortcut_card.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/account_card_standard.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/other_accounts_list.dart";

import "package:ownfinances/features/dashboard/presentation/widgets/debts_section.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_quick_actions.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_filters.dart";
import 'package:ownfinances/l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();
    final state = controller.state;
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      backgroundColor: AppColors.surface1,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          // 0. Header (Implicit in AppScaffold usually, but here added as padding title?)
          // Spec says "Header (título da tela): 'Dashboard'".
          // Assuming AppScaffold handles AppBar title "Dashboard".
          // If body starts here:

          // 1. Shortcut Card (Category Summary)
          const DashboardShortcutCard(),
          const SizedBox(height: AppSpacing.lg),

          // 2. Priority Debts (If due in <= 7 days)
          if (state.hasPriorityDebt) ...[
            DebtsSection(
              activeDebts: state.activeDebts,
              totalPaidThisMonth: state.totalPaidDebts,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // 3. Main Accounts (Carousel)
          if (state.mainAccounts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dashboardMainAccounts,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        l10n.dashboardMainAccountsDesc,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.surface3,
                              title: Text(
                                l10n.dashboardMainAccountsInfoTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                l10n.dashboardMainAccountsInfoBody,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(l10n.commonUnderstood),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220, // Approx height for card
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: state.mainAccounts.length,
                itemBuilder: (context, index) {
                  final summary = state.mainAccounts[index];
                  return AccountCardStandard(
                    summary: summary,
                    onTap: () {
                      final start = DateTime(
                        state.date.year,
                        state.date.month,
                        1,
                      );
                      final end = DateTime(
                        state.date.year,
                        state.date.month + 1,
                        0,
                        23,
                        59,
                        59,
                        59,
                      );

                      context.read<TransactionsController>().setFilters(
                        TransactionFilters(
                          dateFrom: start,
                          dateTo: end,
                          accountId: summary.account.id,
                        ),
                      );

                      context.go("/transactions");
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // 4. Other Accounts
          if (state.otherAccounts.isNotEmpty) ...[
            OtherAccountsList(accounts: state.otherAccounts),
            const SizedBox(height: AppSpacing.lg),
          ],

          // 6. Normal Debts (If NOT Priority)
          // "Se existir vencimento... sobe para #2".
          // Otherwise it stays here.
          if (!state.hasPriorityDebt) ...[
            DebtsSection(
              activeDebts: state.activeDebts,
              totalPaidThisMonth: state.totalPaidDebts,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // 7. Quick Actions
          const SizedBox(height: 12),
          const DashboardQuickActions(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

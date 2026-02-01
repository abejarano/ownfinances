import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/features/dashboard/application/controllers/dashboard_controller.dart";
import "package:ownfinances/features/dashboard/application/state/dashboard_state.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/account_card_standard.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_quick_actions.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/dashboard_shortcut_card.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/debts_section.dart";
import "package:ownfinances/features/dashboard/presentation/widgets/other_accounts_list.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_filters.dart";
import 'package:ownfinances/l10n/app_localizations.dart';
import "package:provider/provider.dart";

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
      child: state.isLoading
          ? const _DashboardSkeleton()
          : _buildContent(context, state, l10n),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DashboardState state,
    AppLocalizations l10n,
  ) {
    return ListView(
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
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _SkeletonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SkeletonBox(height: 16, width: 140),
                SizedBox(height: AppSpacing.sm),
                _SkeletonBox(height: 22),
                SizedBox(height: AppSpacing.sm),
                _SkeletonBox(height: 12, width: 180),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SkeletonBox(height: 16, width: 160),
              SizedBox(height: AppSpacing.sm),
              _SkeletonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(height: 12, width: 120),
                    SizedBox(height: AppSpacing.sm),
                    _SkeletonBox(height: 28),
                    SizedBox(height: AppSpacing.sm),
                    _SkeletonBox(height: 12, width: 180),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SkeletonBox(height: 16, width: 170),
              SizedBox(height: 6),
              _SkeletonBox(height: 12, width: 210),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return const SizedBox(
                width: 260,
                child: _SkeletonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(height: 14, width: 140),
                      SizedBox(height: AppSpacing.sm),
                      _SkeletonBox(height: 24),
                      SizedBox(height: AppSpacing.sm),
                      _SkeletonBox(height: 12, width: 120),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemCount: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SkeletonBox(height: 16, width: 130),
              SizedBox(height: AppSpacing.sm),
              _SkeletonCard(
                child: Column(
                  children: [
                    _SkeletonBox(height: 14),
                    SizedBox(height: AppSpacing.sm),
                    _SkeletonBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _SkeletonBox(height: 48, width: 72),
              _SkeletonBox(height: 48, width: 72),
              _SkeletonBox(height: 48, width: 72),
              _SkeletonBox(height: 48, width: 72),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final Widget child;

  const _SkeletonCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;

  const _SkeletonBox({required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
    );
  }
}

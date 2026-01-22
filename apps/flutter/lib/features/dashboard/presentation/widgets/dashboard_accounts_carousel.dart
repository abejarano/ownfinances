import 'package:flutter/material.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/features/dashboard/application/state/dashboard_state.dart';
import 'dashboard_account_card.dart';

class DashboardAccountsCarousel extends StatelessWidget {
  final List<DashboardAccountSummary> summaries;
  final Function(String accountId) onTap;

  const DashboardAccountsCarousel({
    super.key,
    required this.summaries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 190, // Card height + padding
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: summaries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final summary = summaries[index];
          return SizedBox(
            width: 280,
            child: DashboardAccountCard(
              summary: summary,
              onTap: () => onTap(summary.account.id),
            ),
          );
        },
      ),
    );
  }
}

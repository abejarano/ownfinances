import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/l10n/app_localizations.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            AppLocalizations.of(context)!.dashboardQuickActionsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.arrow_downward,
                  label: AppLocalizations.of(
                    context,
                  )!.dashboardQuickActionExpense,
                  color: AppColors.warning,
                  onTap: () => context.push("/transactions/new?type=expense"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.arrow_upward,
                  label: AppLocalizations.of(
                    context,
                  )!.dashboardQuickActionIncome,
                  color: AppColors.success,
                  onTap: () => context.push("/transactions/new?type=income"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.compare_arrows,
                  label: AppLocalizations.of(
                    context,
                  )!.dashboardQuickActionTransfer,
                  color: AppColors.info,
                  onTap: () => context.push("/transactions/new?type=transfer"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.repeat,
                  label: AppLocalizations.of(
                    context,
                  )!.dashboardQuickActionFixed,
                  color: const Color(0xFFC084FC), // Violet
                  onTap: () => context.go("/budget?tab=fixed"),
                ),
              ),
            ],
          ),
        ),
      ],
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
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

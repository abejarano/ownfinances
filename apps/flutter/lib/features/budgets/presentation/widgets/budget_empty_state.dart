import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetEmptyState extends StatelessWidget {
  final String month;
  final VoidCallback onCreate;

  const BudgetEmptyState({
    super.key,
    required this.month,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.md,
        ),
        child: Column(
          children: [
            const Icon(Icons.money_off, size: 64, color: AppColors.muted),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.budgetsEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.budgetsEmptyDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: AppLocalizations.of(context)!.budgetsCreateButton,
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

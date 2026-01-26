import "package:flutter/material.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/l10n/app_localizations.dart";

class BudgetSegmentsControl extends StatelessWidget {
  const BudgetSegmentsControl({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: [
          Tab(text: l10n.budgetsSegmentCategories),
          Tab(text: l10n.budgetsSegmentDebts),
          Tab(text: l10n.budgetsSegmentSummary),
        ],
      ),
    );
  }
}

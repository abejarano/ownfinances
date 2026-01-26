import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/l10n/app_localizations.dart";

typedef GoalExampleSelected = void Function(
  String name,
  DateTime? targetDate,
);

class GoalsEmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final GoalExampleSelected onExampleSelected;

  const GoalsEmptyState({
    super.key,
    required this.onCreate,
    required this.onExampleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final examples = [
      _GoalExampleData(label: l10n.goalsEmptyExampleEmergency),
      _GoalExampleData(
        label: l10n.goalsEmptyExampleTrip,
        targetDate: _addMonths(now, 3),
      ),
      _GoalExampleData(label: l10n.goalsEmptyExampleBigPurchase),
      _GoalExampleData(label: l10n.goalsEmptyExampleBillsBuffer),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(
                Icons.flag_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.goalsEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.goalsEmptyDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.goalsEmptyBullet1,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.goalsEmptyBullet2,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.goalsEmptyBullet3,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.goalsEmptyExamplesTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final example in examples)
                  _GoalExampleChip(
                    label: example.label,
                    onTap: () => onExampleSelected(
                      example.label,
                      example.targetDate,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.goalsEmptyCta,
              onPressed: onCreate,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.goalsEmptyMicrocopy,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.month + months;
    final year = date.year + ((totalMonths - 1) ~/ 12);
    final month = ((totalMonths - 1) % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }
}

class GoalsInlineHelp extends StatefulWidget {
  const GoalsInlineHelp({super.key});

  @override
  State<GoalsInlineHelp> createState() => _GoalsInlineHelpState();
}

class _GoalsInlineHelpState extends State<GoalsInlineHelp> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.help_outline,
            size: 18,
          ),
          label: Text(l10n.goalsHelpToggle),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: EdgeInsets.zero,
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Text(
              l10n.goalsEmptyDescription,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          crossFadeState:
              _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
      ],
    );
  }
}

class _GoalExampleData {
  final String label;
  final DateTime? targetDate;

  const _GoalExampleData({required this.label, this.targetDate});
}

class _GoalExampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GoalExampleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

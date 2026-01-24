import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/features/recurring/application/controllers/recurring_controller.dart';
import 'package:ownfinances/features/transactions/application/controllers/pending_transactions_controller.dart';
import 'package:ownfinances/l10n/app_localizations.dart';

class RecurrenceSummaryCard extends StatefulWidget {
  const RecurrenceSummaryCard({super.key});

  @override
  State<RecurrenceSummaryCard> createState() => _RecurrenceSummaryCardState();
}

class _RecurrenceSummaryCardState extends State<RecurrenceSummaryCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<RecurringController>();
      controller.loadPendingSummary();
      controller.load(); // Load rules to check if any exist
      context.read<PendingTransactionsController>().loadPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recurrenceState = context.watch<RecurringController>().state;
    final pendingState = context.watch<PendingTransactionsController>().state;

    if (recurrenceState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final toGenerateCount = recurrenceState.toGenerateCount;
    final hasRules = recurrenceState.items.isNotEmpty;
    final pendingCount = pendingState.items.length;

    // Determine State
    // State A: To Generate
    if (toGenerateCount > 0) {
      return _buildStateA(context, toGenerateCount, pendingCount);
    }

    // State C: No Rules (and thus no generation needed)
    if (!hasRules) {
      return _buildStateC(context);
    }

    // State B: All Done (Rules exist but nothing to generate)
    return _buildStateB(context);
  }

  Widget _buildStateA(BuildContext context, int count, int pendingCount) {
    return Card(
      color: AppColors.warningSoft,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide
            .none, // PO spec: no hard border if soft bg? Or usage BORDER-soft? Soft backgrounds usually imply no border or soft border. Spec says "background: WARNING-soft".
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.recurringMissingGenerated(count),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors
                          .textPrimary, // Or Warning? Spec: "texto: TEXT-primary"
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/recurring/plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.bg0, // Contrast text
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.recurringPlanMonth,
                    ),
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.push('/transactions/pending'),
                    child: Text(
                      AppLocalizations.of(context)!.recurringViewPending,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateB(BuildContext context) {
    // Compact Row style as per "Desquadra Dark Calm" spec
    // Background SURFACE-1 (Card default)
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text(
              "${AppLocalizations.of(context)!.onboardingAllSet} ✅",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/recurring'), // Link "Ver regras"
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(AppLocalizations.of(context)!.recurringViewRules),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateC(BuildContext context) {
    return Card(
      // Defaults to SURFACE-1
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.recurringNoRulesYet,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.recurringCreateFirst),
              onPressed: () => context.push('/recurring/new'),
            ),
          ],
        ),
      ),
    );
  }
}

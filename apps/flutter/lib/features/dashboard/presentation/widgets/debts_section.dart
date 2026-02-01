import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ownfinances/core/presentation/components/buttons.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/core/utils/formatters.dart';
import 'package:ownfinances/features/debts/domain/entities/debt.dart';
import 'package:ownfinances/l10n/app_localizations.dart';

class DebtsSection extends StatelessWidget {
  final List<Debt> activeDebts;
  final double totalPaidThisMonth;

  const DebtsSection({
    super.key,
    required this.activeDebts,
    required this.totalPaidThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    if (activeDebts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.debtsSectionTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.debtsEmptyState,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push("/debts"),
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.debtsActionAdd),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Calculate total due and find nearest due date
    double totalDue = 0;
    Debt? nearestDebt;
    DateTime? nearestDueDate;
    int minDays = 999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final debt in activeDebts) {
      totalDue += debt.amountDue;

      if (debt.dueDay != null) {
        DateTime nextDue;
        if (debt.dueDay! >= today.day) {
          nextDue = DateTime(today.year, today.month, debt.dueDay!);
        } else {
          nextDue = DateTime(today.year, today.month + 1, debt.dueDay!);
        }
        final diff = nextDue.difference(today).inDays;
        if (diff >= 0 && diff < minDays) {
          minDays = diff;
          nearestDebt = debt;
          nearestDueDate = nextDue;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.debtsSectionTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              TextButton(
                onPressed: () => context.push("/debts"),
                child: Text(
                  AppLocalizations.of(context)!.debtsActionViewAll,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NEW: Paid This Month
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.debtsPaidMonth,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      formatCurrency(totalPaidThisMonth, "BRL"),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 16),

                Text(
                  AppLocalizations.of(context)!.debtsTotalToPay,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatCurrency(totalDue, "BRL"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (nearestDebt != null && nearestDueDate != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.debtsNextDue(
                            "${nearestDueDate.day.toString().padLeft(2, '0')}/${nearestDueDate.month.toString().padLeft(2, '0')}",
                            nearestDebt.name,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: AppLocalizations.of(context)!.debtsActionPay,
                    onPressed: () => context.push("/debts"),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.debtsPaymentDisclaimer,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

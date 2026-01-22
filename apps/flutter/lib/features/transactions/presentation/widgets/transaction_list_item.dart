import "package:flutter/material.dart";

import "package:ownfinances/core/presentation/components/money_text.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/accounts/domain/entities/account.dart";
import "package:ownfinances/features/categories/domain/entities/category.dart";

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final Account? fromAccount;
  final Account? toAccount;
  final Category? category;
  final String? filterContextAccountId;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Future<bool> Function() onConfirmDelete;

  const TransactionListItem({
    required this.transaction,
    required this.onTap,
    required this.onDelete,
    required this.onConfirmDelete,
    this.fromAccount,
    this.toAccount,
    this.category,
    this.filterContextAccountId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final presenter = _TransactionPresenter(
      transaction,
      fromAccount,
      toAccount,
      category,
      filterContextAccountId,
    );

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) => onConfirmDelete(),
      onDismissed: (direction) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface1,
            border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              _buildIcon(presenter),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildMainContent(context, presenter)),
              _buildTrailing(presenter),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(_TransactionPresenter presenter) {
    return CircleAvatar(
      backgroundColor: presenter.iconBg,
      foregroundColor: presenter.iconColor,
      child: Icon(presenter.iconData, size: 20),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    _TransactionPresenter presenter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          presenter.title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          presenter.subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTrailing(_TransactionPresenter presenter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (presenter.useCustomRender)
          _buildMultiCurrencyTrailing(presenter)
        else
          MoneyText(
            value: presenter.displayAmount,
            variant: MoneyTextVariant.m,
            color: presenter.amountColor,
            symbol: presenter.displayCurrency,
          ),
        const SizedBox(height: 6),
        if (!presenter.isPending) _buildStatusChip(presenter),
      ],
    );
  }

  Widget _buildMultiCurrencyTrailing(_TransactionPresenter presenter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "${presenter.sourceCurrency} ${formatMoney(presenter.sourceVal, withSymbol: false)} →",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          "${presenter.destCurrency} ${formatMoney(presenter.destVal, withSymbol: false)}",
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(_TransactionPresenter presenter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: presenter.statusBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        presenter.statusLabel,
        style: TextStyle(
          color: presenter.statusColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Handles the complex display logic, keeping the Widget clean.
class _TransactionPresenter {
  final Transaction item;
  final Account? from;
  final Account? to;
  final Category? category;
  final String? filterId;

  _TransactionPresenter(
    this.item,
    this.from,
    this.to,
    this.category,
    this.filterId,
  );

  String get title {
    if (item.type == 'transfer') return "Transferência";
    if (item.note != null && item.note!.isNotEmpty) return item.note!;
    if (category != null) return category!.name;
    return item.type == "income" ? "Receita" : "Despesa";
  }

  String get subtitle {
    if (item.type == 'transfer') return _transferSubtitle;

    // Income/Expense Subtitle
    final accountName =
        (item.type == 'income' ? to?.name : from?.name) ?? "Sem conta";
    if (item.note != null && item.note!.isNotEmpty && category != null) {
      return "${category!.name} • $accountName";
    }
    return accountName;
  }

  String get _transferSubtitle {
    final fromName = from?.name ?? '?';
    final toName = to?.name ?? '?';

    // Case A: Overview
    if (filterId == null || filterId!.isEmpty) {
      if (isCurrencyMismatch) {
        return "$fromName ($sourceCurrency) → $toName ($destCurrency)";
      }
      return "$fromName → $toName";
    }

    // Case B: Outflow (Filter == From)
    if (filterId == item.fromAccountId) {
      if (isCurrencyMismatch && destVal > 0) {
        return "para $toName (${fmt(destVal, destCurrency)})";
      }
      return "para $toName";
    }

    // Case C: Inflow (Filter == To)
    if (filterId == item.toAccountId) {
      if (isCurrencyMismatch) {
        return "de $fromName (${fmt(sourceVal, sourceCurrency)})";
      }
      return "de $fromName";
    }

    return "$fromName → $toName";
  }

  // --- Amounts & Currencies ---

  bool get isCurrencyMismatch => sourceCurrency != destCurrency;
  String get sourceCurrency => from?.currency ?? item.currency;
  String get destCurrency =>
      to?.currency ?? ""; // Empty if logic fails, but usually valid

  double get sourceVal => item.amount;
  double get destVal =>
      item.destinationAmount ??
      (sourceCurrency == destCurrency ? sourceVal : 0);

  bool get useCustomRender =>
      item.type == 'transfer' &&
      (filterId == null || filterId!.isEmpty) &&
      isCurrencyMismatch;

  double get displayAmount {
    if (item.type == 'expense') return -item.amount;
    if (item.type == 'income') return item.amount;

    // Transfer Logic
    if (filterId == item.fromAccountId) return -sourceVal;
    if (filterId == item.toAccountId) return destVal > 0 ? destVal : sourceVal;

    // Overview Same Currency
    return -sourceVal; // Used as neutral indicator usually
  }

  String get displayCurrency {
    if (item.type == 'income') return to?.currency ?? item.currency;
    if (item.type == 'expense') return from?.currency ?? item.currency;

    // Transfer logic
    if (filterId == item.toAccountId && destCurrency.isNotEmpty)
      return destCurrency;
    return sourceCurrency;
  }

  Color get amountColor {
    if (item.type == 'income') return AppColors.success;
    if (item.type == 'expense') return AppColors.warning;

    // Transfer
    if (filterId == item.fromAccountId) return AppColors.warning;
    if (filterId == item.toAccountId) return AppColors.success;
    return AppColors.textPrimary; // Neutral
  }

  // --- Visuals ---

  IconData get iconData {
    if (category?.icon != null) return _getIconData(category!.icon!);
    if (item.type == 'transfer') return Icons.swap_horiz;
    return Icons.category;
  }

  Color get iconColor {
    if (item.type == 'income') return AppColors.success;
    if (item.type == 'transfer') return AppColors.info;
    return AppColors.warning;
  }

  Color get iconBg {
    if (item.type == 'income') return AppColors.successSoft;
    if (item.type == 'transfer') return AppColors.infoSoft;
    return AppColors.warningSoft;
  }

  bool get isPending => item.status == 'pending';
  Color get statusColor => isPending ? AppColors.warning : AppColors.success;
  Color get statusBg =>
      isPending ? AppColors.warningSoft : AppColors.successSoft;
  String get statusLabel => isPending ? "Pendente" : "Confirmado";

  String fmt(double val, String curr) =>
      "$curr ${formatMoney(val, withSymbol: false)}";

  IconData _getIconData(String iconName) {
    // Map icons (Simplified for brevity, can import map)
    const map = {
      "salary": Icons.attach_money,
      "restaurant": Icons.restaurant,
      "home": Icons.home,
      "transport": Icons.directions_car,
      "leisure": Icons.movie,
      "health": Icons.medical_services,
      "shopping": Icons.shopping_bag,
      "bills": Icons.receipt_long,
      "entertainment": Icons.sports_esports,
      "education": Icons.school,
      "gym": Icons.fitness_center,
      "travel": Icons.flight,
      "gift": Icons.card_giftcard,
      "investment": Icons.trending_up,
      "family": Icons.family_restroom,
    };
    return map[iconName] ?? Icons.category;
  }
}

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";
import 'package:ownfinances/core/presentation/components/fliter_chip.dart';
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction_filters.dart";
// Import the new widget
import "package:ownfinances/features/transactions/presentation/widgets/transaction_list_item.dart";
import "package:ownfinances/l10n/app_localizations.dart";
import "package:provider/provider.dart";

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txController = context.read<TransactionsController>();
    final txState = context.watch<TransactionsController>().state;
    // Watch Categories and Accounts to ensure lookups work
    final categoriesState = context.watch<CategoriesController>().state;
    final accountsState = context.watch<AccountsController>().state;
    final filters = txState.filters;

    // Process transactions for grouping
    final groupedTransactions = _groupTransactionsByDate(
      txState.items,
      context,
    );

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, txController),
            _buildFilters(context, filters, txController),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: txState.items.isEmpty
                  ? _buildEmptyState(context)
                  : NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (!txState.isLoadingMore &&
                            scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent - 200) {
                          txController.loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount:
                            groupedTransactions.length +
                            (txState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= groupedTransactions.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final item = groupedTransactions[index];
                          if (item is String) {
                            return _buildDateHeader(context, item);
                          } else if (item is Transaction) {
                            return _buildTransactionItem(
                              context,
                              item,
                              categoriesState.items,
                              accountsState.items,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TransactionsController controller) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () => context.push("/csv-import"),
            tooltip: AppLocalizations.of(context)!.transactionsActionImportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.load,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    TransactionFilters filters,
    TransactionsController controller,
  ) {
    final currentMonthLabel = formatMonth(
      filters.dateFrom ?? DateTime.now(),
    ).toUpperCase();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          CustomFilterChip(
            label: currentMonthLabel,
            icon: Icons.calendar_today,
            isActive: true, // Always show active for the main date filter
            onTap: () => _pickMonth(context, filters),
          ),
          const SizedBox(width: AppSpacing.sm),
          CustomFilterChip(
            label: AppLocalizations.of(context)!.transactionsLabelAccount,
            isActive:
                filters.accountId != null && filters.accountId!.isNotEmpty,
            onTap: () => _showAccountPicker(context, filters),
          ),
          const SizedBox(width: AppSpacing.sm),
          CustomFilterChip(
            label: AppLocalizations.of(context)!.transactionsLabelCategory,
            isActive:
                filters.categoryId != null && filters.categoryId!.isNotEmpty,
            onTap: () => _showCategoryPicker(context, filters),
          ),
          const SizedBox(width: AppSpacing.sm),
          CustomFilterChip(
            label: AppLocalizations.of(context)!.transactionsLabelStatus,
            isActive: filters.status != null,
            onTap: () => _showStatusPicker(context, filters),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Transaction item,
    List<dynamic> categories,
    List<dynamic> accounts,
  ) {
    final categoryMap = {for (final c in categories) c.id: c};
    final accountMap = {for (final a in accounts) a.id: a};

    final category = categoryMap[item.categoryId];
    final fromAccount = accountMap[item.fromAccountId];
    final toAccount = accountMap[item.toAccountId];

    final filters = context.read<TransactionsController>().state.filters;
    final filterAccountId = filters.accountId;

    return TransactionListItem(
      transaction: item,
      fromAccount: fromAccount,
      toAccount: toAccount,
      category: category,
      filterContextAccountId: filterAccountId,
      onTap: () => context.push("/transactions/edit", extra: item),
      onDelete: () => _deleteTransaction(context, item),
      onConfirmDelete: () => _confirmDelete(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 48, color: AppColors.textTertiary),
          SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context)!.transactionsEmptyState,
            style: const TextStyle(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface3,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.arrow_downward,
                color: AppColors.warning,
              ),
              title: Text(
                AppLocalizations.of(context)!.transactionTypeExpense,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go("/transactions/new?type=expense");
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: AppColors.success),
              title: Text(
                AppLocalizations.of(context)!.transactionTypeIncome,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go("/transactions/new?type=income");
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppColors.info),
              title: Text(
                AppLocalizations.of(context)!.transactionTypeTransfer,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go("/transactions/new?type=transfer");
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  List<dynamic> _groupTransactionsByDate(
    List<Transaction> items,
    BuildContext context,
  ) {
    if (items.isEmpty) return [];

    final grouped = <dynamic>[];
    String? lastDate;

    for (final item in items) {
      final dateStr = _formatHeaderDate(item.date, context);
      if (lastDate != dateStr) {
        grouped.add(dateStr);
        lastDate = dateStr;
      }
      grouped.add(item);
    }
    return grouped;
  }

  String _formatHeaderDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return AppLocalizations.of(context)!.commonToday;
    if (itemDate == yesterday)
      return AppLocalizations.of(context)!.commonYesterday;

    return DateFormat("EEEE, d 'de' MMMM").format(date);
  }

  // --- Filter Actions ---

  Future<void> _pickMonth(
    BuildContext context,
    TransactionFilters filters,
  ) async {
    final initial = filters.dateFrom ?? DateTime.now();

    pickMonth(context, initialDate: initial, (int year, int month) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0, 23, 59, 59);

      context.read<TransactionsController>().setFilters(
        filters.copyWith(dateFrom: start, dateTo: end),
      );
    });
  }

  Future<void> _showAccountPicker(
    BuildContext context,
    TransactionFilters filters,
  ) async {
    final accounts = context.read<AccountsController>().state.items;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface3,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.transactionsFilterAllAccounts,
            ),
            onTap: () {
              context.read<TransactionsController>().setFilters(
                filters.copyWith(accountId: ""), // Clear
              );
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: accounts
                  .map(
                    (acc) => ListTile(
                      title: Text(acc.name),
                      selected: filters.accountId == acc.id,
                      selectedColor: AppColors.primary,
                      onTap: () {
                        context.read<TransactionsController>().setFilters(
                          filters.copyWith(accountId: acc.id),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    TransactionFilters filters,
  ) async {
    final categories = context.read<CategoriesController>().state.items;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface3,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.transactionsFilterAllCategories,
            ),
            onTap: () {
              context.read<TransactionsController>().setFilters(
                filters.copyWith(categoryId: ""), // Clear
              );
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: categories
                  .map(
                    (cat) => ListTile(
                      title: Text(cat.name),
                      selected: filters.categoryId == cat.id,
                      selectedColor: AppColors.primary,
                      onTap: () {
                        context.read<TransactionsController>().setFilters(
                          filters.copyWith(categoryId: cat.id),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusPicker(
    BuildContext context,
    TransactionFilters filters,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface3,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.transactionsFilterAllStatus,
            ),
            onTap: () {
              context.read<TransactionsController>().setFilters(
                filters.copyWith(status: null),
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.transactionsFilterPending,
            ),
            onTap: () {
              context.read<TransactionsController>().setFilters(
                filters.copyWith(status: "pending"),
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.transactionsFilterConfirmed,
            ),
            onTap: () {
              context.read<TransactionsController>().setFilters(
                filters.copyWith(status: "cleared"),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.transactionsDeleteTitle),
            content: Text(AppLocalizations.of(context)!.transactionsDeleteDesc),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  AppLocalizations.of(context)!.commonDelete,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    Transaction item,
  ) async {
    final controller = context.read<TransactionsController>();
    final reportsController = context.read<ReportsController>();
    final period = context.read<ReportsController>().state.period;

    final result = await controller.removeWithImpact(
      id: item.id,
      period: period,
    );

    if (result?.impact != null && context.mounted) {
      reportsController.applyImpactFromJson(result!.impact!);
    } else {
      await reportsController.load();
    }
  }
}

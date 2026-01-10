import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "package:intl/intl.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txController = context.read<TransactionsController>();
    final txState = context.watch<TransactionsController>().state;
    final filters = txState.filters;

    // Process transactions for grouping
    final groupedTransactions = _groupTransactionsByDate(txState.items);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, txController),
            _buildFilters(context, filters, txController),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: txState.items.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: groupedTransactions.length,
                      itemBuilder: (context, index) {
                        final item = groupedTransactions[index];
                        if (item is String) {
                          return _buildDateHeader(context, item);
                        } else if (item is Transaction) {
                          return _buildTransactionItem(context, item);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TransactionsController controller) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Transações",
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.upload_file_outlined),
                onPressed: () => context.push("/csv-import"),
                tooltip: "Importar CSV",
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.load,
              ),
            ],
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
          _FilterChip(
            label: currentMonthLabel,
            icon: Icons.calendar_today,
            isActive: true, // Always show active for the main date filter
            onTap: () => _pickMonth(context, filters),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: "Conta",
            isActive:
                filters.accountId != null && filters.accountId!.isNotEmpty,
            onTap: () => _showAccountPicker(context, filters),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: "Categoria",
            isActive:
                filters.categoryId != null && filters.categoryId!.isNotEmpty,
            onTap: () => _showCategoryPicker(context, filters),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: "Status",
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
          color: AppColors.muted,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction item) {
    final categoryMap = {
      for (final c in context.read<CategoriesController>().state.items) c.id: c,
    };
    final accountMap = {
      for (final a in context.read<AccountsController>().state.items)
        a.id: a.name,
    };

    final category = categoryMap[item.categoryId];
    final fromName = accountMap[item.fromAccountId];
    final toName = accountMap[item.toAccountId];

    final title = _titleFor(item.type, category?.name);
    final subtitle = _subtitleFor(item, fromName, toName);
    final amount = formatMoney(item.amount);
    final iconData = _getIconData(category?.icon);
    final iconColor = _getIconColor(category?.color);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _confirmDelete(context);
      },
      onDismissed: (direction) {
        _deleteTransaction(context, item);
      },
      child: InkWell(
        onTap: () => context.push("/transactions/edit", extra: item),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withValues(alpha: 0.1),
                foregroundColor: iconColor,
                child: Icon(iconData, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _amountPrefix(item.type) + amount,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: item.type == "income"
                          ? Colors.green
                          : item.type == "expense"
                          ? Colors.white
                          : AppColors.muted,
                    ),
                  ),
                  if (item.status == "cleared")
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 48, color: AppColors.muted),
          SizedBox(height: AppSpacing.md),
          Text(
            "Nenhuma transação encontrada",
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.green),
              title: const Text("Receita"),
              onTap: () {
                Navigator.pop(context);
                context.go("/transactions/new?type=income");
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.red),
              title: const Text("Despesa"),
              onTap: () {
                Navigator.pop(context);
                context.go("/transactions/new?type=expense");
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.blue),
              title: const Text("Transferência"),
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

  List<dynamic> _groupTransactionsByDate(List<Transaction> items) {
    if (items.isEmpty) return [];

    final grouped = <dynamic>[];
    String? lastDate;

    for (final item in items) {
      final dateStr = _formatHeaderDate(item.date);
      if (lastDate != dateStr) {
        grouped.add(dateStr);
        lastDate = dateStr;
      }
      grouped.add(item);
    }
    return grouped;
  }

  String _formatHeaderDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return "Hoje";
    if (itemDate == yesterday) return "Ontem";

    return DateFormat("EEEE, d 'de' MMMM", "pt_BR").format(date);
  }

  String _titleFor(String type, String? categoryName) {
    if (type == "transfer") return "Transferência";
    return categoryName ?? (type == "income" ? "Receita" : "Despesa");
  }

  String _subtitleFor(Transaction item, String? fromName, String? toName) {
    if (item.type == "transfer") {
      return "${fromName ?? "?"} → ${toName ?? "?"}";
    }
    final account = item.type == "income" ? toName : fromName;
    return account ?? "Conta desconhecida";
  }

  String _amountPrefix(String type) {
    if (type == "income") return "+ ";
    if (type == "transfer") return "";
    return "- ";
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case "salary":
        return Icons.attach_money;
      case "restaurant":
        return Icons.restaurant;
      case "home":
        return Icons.home;
      case "transport":
        return Icons.directions_car;
      case "leisure":
        return Icons.movie;
      case "health":
        return Icons.medical_services;
      case "shopping":
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  Color _getIconColor(String? colorHex) {
    if (colorHex == null) return Colors.grey;
    try {
      return Color(int.parse(colorHex.replaceAll("#", "0xFF")));
    } catch (_) {
      return Colors.grey;
    }
  }

  // --- Filter Actions ---

  Future<void> _pickMonth(
    BuildContext context,
    TransactionFilters filters,
  ) async {
    final initial = filters.dateFrom ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;

    if (!context.mounted) return;

    final start = DateTime(selected.year, selected.month, 1);
    final end = DateTime(selected.year, selected.month + 1, 0, 23, 59, 59);

    context.read<TransactionsController>().setFilters(
      filters.copyWith(dateFrom: start, dateTo: end),
    );
  }

  Future<void> _showAccountPicker(
    BuildContext context,
    TransactionFilters filters,
  ) async {
    final accounts = context.read<AccountsController>().state.items;

    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("Todas as contas"),
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
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("Todas as categorias"),
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
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("Todos"),
            onTap: () {
              context.read<TransactionsController>().setFilters(
                filters.copyWith(status: null),
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("Pendente"),
            onTap: () {
              context.read<TransactionsController>().setFilters(
                filters.copyWith(status: "pending"),
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("Confirmado"),
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
            title: const Text("Excluir transação?"),
            content: const Text("Essa ação não pode ser desfeita."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Excluir",
                  style: TextStyle(color: Colors.red),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.muted,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isActive ? AppColors.primary : AppColors.muted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.muted,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

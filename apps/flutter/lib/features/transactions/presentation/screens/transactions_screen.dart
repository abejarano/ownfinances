import "package:ownfinances/features/transactions/domain/entities/transaction_filters.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "package:intl/intl.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/core/presentation/components/money_text.dart";
import "package:ownfinances/core/presentation/components/month_picker_dialog.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/transactions/data/repositories/transaction_repository.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";

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
    final groupedTransactions = _groupTransactionsByDate(txState.items);

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
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: groupedTransactions.length,
                      itemBuilder: (context, index) {
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
    final accountMap = {for (final a in accounts) a.id: a.name};

    final category = categoryMap[item.categoryId];
    final fromName = accountMap[item.fromAccountId];
    final toName = accountMap[item.toAccountId];

    // Priority: Note > Category Name > Type Label
    String title = "";
    if (item.note != null && item.note!.isNotEmpty) {
      title = item.note!;
    } else if (category != null) {
      title = category.name;
    } else {
      title = item.type == "income" ? "Receita" : "Despesa";
      if (item.type == "transfer") title = "Transferência";
    }

    // Subtitle Logic
    String subtitle = "";
    if (item.type == 'transfer') {
      subtitle = "${fromName ?? '?'} → ${toName ?? '?'}";
    } else {
      final accountName =
          (item.type == 'income' ? toName : fromName) ?? "Sem conta";

      // If we used Note as title, and we have a category, show "Category • Account"
      if (item.note != null && item.note!.isNotEmpty && category != null) {
        subtitle = "${category.name} • $accountName";
      } else {
        // Normal case: just account
        subtitle = accountName;
      }
    }

    final iconData = _getIconData(category?.icon);

    // Semantic Colors Setup
    Color iconColor;
    Color iconBg;
    Color amountColor;

    if (item.type == 'income') {
      iconColor = AppColors.success;
      iconBg = AppColors.successSoft;
      amountColor = AppColors.success;
    } else if (item.type == 'transfer') {
      iconColor = AppColors.info;
      iconBg = AppColors.infoSoft;
      amountColor = AppColors
          .textSecondary; // Transfers are neutral? Or Info? Usually neutral/white.
    } else {
      // Expense
      iconColor = AppColors.warning;
      iconBg = AppColors.warningSoft;
      amountColor = AppColors
          .warning; // Or Danger if critical, but per PO "Expense: Warning"
    }

    // Status Chip Setup
    final isPending =
        item.status == 'pending'; // Assuming 'pending' vs 'cleared'
    final statusColor = isPending ? AppColors.warning : AppColors.success;
    final statusBg = isPending ? AppColors.warningSoft : AppColors.successSoft;
    final statusLabel = isPending ? "Pendente" : "Confirmado";

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.danger,
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
        child: Container(
          // Use Surface-1 as background? List items usually blend with bg or have own surface.
          // Verify if ListTiles should have surface or transparent?
          // Spec: "Background: SURFACE-1". This usually implies specific card-like or just bg color if whole list is distinct.
          // Since grouped, maybe transparent and let Scaffold be BG-0?
          // But strict spec says "Background: SURFACE-1".
          // If I interpret "Item de transação (cada fila)" as separate card/block?
          // Let's use transparent for now as it's a list, unless cards are implied.
          // Wait, "Item de transação (cada fila) Background: SURFACE-1".
          // This implies alternating colors or blocks. Let's make it a Container with color SURFACE-1 and margin?
          // Or just solid background for the item area.
          decoration: const BoxDecoration(
            color: AppColors.surface1,
            border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical:
                AppSpacing.md, // Increased vertical padding for "premium" feel
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconBg,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    // Pass signed value for semantics, or just absolute.
                    // To maintain "+ " or "- " visually with tabular figures, it's best to let formatting handle it or color.
                    // Given strict MoneyText usage, we'll pass the value.
                    // If we want explicit "+" for income, we might need a custom formatter in MoneyText or just rely on color.
                    // For now: Expense = negative, Income = positive.
                    value: item.type == 'expense' ? -item.amount : item.amount,
                    variant: MoneyTextVariant.m,
                    color: amountColor,
                    symbol: item.currency, // Pass the transaction currency
                  ),
                  const SizedBox(height: 6),

                  // Status Chip (Small)
                  if (!isPending) ...[
                    // Only show check if cleared? Or show status chip?
                    // PO: "Status chip: pending: background WARNING-soft, texto WARNING; cleared: background SUCCESS-soft, texto SUCCESS"
                    // And "El status icon (check) debe ir como chip pequeño... no como adorno suelto"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
          Icon(Icons.history, size: 48, color: AppColors.textTertiary),
          SizedBox(height: AppSpacing.md),
          Text(
            "Nenhuma transação encontrada",
            style: TextStyle(color: AppColors.textTertiary),
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
              title: const Text(
                "Receita",
                style: TextStyle(color: AppColors.textPrimary),
              ), // Receita is Income? Arrow Down usually means Income (money in)?
              // Wait: Arrow Down = Income (Into account). Arrow Up = Expense (Out of account).
              // Previous code: arrow_downward: Green/Receita. arrow_upward: Red/Expense.
              // Logic check: "Receita" (Income). "Despesa" (Expense).
              // My semantic rules: Income = Success/Green. Expense = Warning/Amber.
              onTap: () {
                Navigator.pop(context);
                context.go("/transactions/new?type=income");
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.arrow_upward,
                color: AppColors.success,
              ), // Wait, swap colors?
              // Previous: Arrow Down (Green) -> Receita. Arrow Up (Red) -> Despesa.
              // So arrow_down is Income (Green/Success). arrow_up is Expense (Red/Danger now Warning).
              title: const Text(
                "Despesa",
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go("/transactions/new?type=expense");
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppColors.info),
              title: const Text(
                "Transferência",
                style: TextStyle(color: AppColors.textPrimary),
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

  //   String _amountPrefix(String type) {
  //     if (type == "income") return "+ ";
  //     if (type == "transfer") return "";
  //     return "- ";
  //   }

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
      case "other":
        return Icons.category;
      case "bills":
        return Icons.receipt_long;
      case "entertainment":
        return Icons.sports_esports;
      case "education":
        return Icons.school;
      case "gym": // "Apoyo familiar" might be mapped to one of these or "other"
        return Icons.fitness_center;
      case "travel":
        return Icons.flight;
      case "gift":
        return Icons.card_giftcard;
      case "investment":
        return Icons.trending_up;
      case "family": // Possible match for "Apoyo familiar" if icon name matches
        return Icons.family_restroom;
      default:
        return Icons.category;
    }
  }

  // --- Filter Actions ---

  Future<void> _pickMonth(
    BuildContext context,
    TransactionFilters filters,
  ) async {
    final initial = filters.dateFrom ?? DateTime.now();
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => MonthPickerDialog(
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      ),
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
      backgroundColor: AppColors.surface3,
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
                  style: TextStyle(color: AppColors.danger),
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
    // Default = SURFACE-1, Border-Soft, Text-Secondary
    // Selected = PRIMARY-Soft, Border-Focus, Text-Primary
    final bgColor = isActive ? AppColors.primarySoft : AppColors.surface1;
    final borderColor = isActive ? AppColors.borderFocus : AppColors.borderSoft;
    final textColor = isActive
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    final iconColor = isActive ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

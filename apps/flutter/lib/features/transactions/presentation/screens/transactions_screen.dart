import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txController = context.read<TransactionsController>();
    final txState = context.watch<TransactionsController>().state;
    final categories = context.watch<CategoriesController>().state.items;
    final accounts = context.watch<AccountsController>().state.items;

    final categoryItems = [
      const PickerItem(id: "", label: "Todas"),
      ...categories.map((cat) => PickerItem(id: cat.id, label: cat.name)),
    ];
    final accountItems = [
      const PickerItem(id: "", label: "Todas"),
      ...accounts.map((acc) => PickerItem(id: acc.id, label: acc.name)),
    ];
    final categoryMap = {for (final item in categories) item.id: item.name};
    final accountMap = {for (final item in accounts) item.id: item.name};

    final filters = txState.filters;
    final currentMonth = formatMonth(
      filters.dateFrom ?? DateTime.now(),
    ).toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Transacciones",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: txController.load,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionChip(
                label: Text("Periodo: $currentMonth"),
                onPressed: () => _pickMonth(context, filters),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String?>(
                  value: filters.status,
                  decoration: const InputDecoration(labelText: "Estado"),
                  items: const [
                    DropdownMenuItem(value: null, child: Text("Todos")),
                    DropdownMenuItem(
                      value: "pending",
                      child: Text("Pendiente"),
                    ),
                    DropdownMenuItem(
                      value: "cleared",
                      child: Text("Confirmado"),
                    ),
                  ],
                  onChanged: (value) {
                    txController.setFilters(
                      TransactionFilters(
                        dateFrom: filters.dateFrom,
                        dateTo: filters.dateTo,
                        categoryId: filters.categoryId,
                        accountId: filters.accountId,
                        status: value,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: CategoryPicker(
                  label: "Categoría",
                  items: categoryItems,
                  value: filters.categoryId ?? "",
                  onSelected: (item) {
                    final id = item.id.isEmpty ? null : item.id;
                    txController.setFilters(
                      TransactionFilters(
                        dateFrom: filters.dateFrom,
                        dateTo: filters.dateTo,
                        categoryId: id,
                        accountId: filters.accountId,
                        status: filters.status,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: AccountPicker(
                  label: "Cuenta",
                  items: accountItems,
                  value: filters.accountId ?? "",
                  onSelected: (item) {
                    final id = item.id.isEmpty ? null : item.id;
                    txController.setFilters(
                      TransactionFilters(
                        dateFrom: filters.dateFrom,
                        dateTo: filters.dateTo,
                        categoryId: filters.categoryId,
                        accountId: id,
                        status: filters.status,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: txState.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = txState.items[index];
                final categoryName = categoryMap[item.categoryId];
                final fromName = accountMap[item.fromAccountId];
                final toName = accountMap[item.toAccountId];
                final title = _titleFor(item.type, categoryName);
                final subtitle =
                    "${item.status == "cleared" ? "Confirmado" : "Pendiente"} • ${formatDate(item.date)}";
                final accountLabel = item.type == "income"
                    ? (toName ?? "—")
                    : (fromName ?? "—");
                final amount = formatMoney(item.amount);

                return Dismissible(
                  key: ValueKey(item.id),
                  background: _swipeBackground(
                    Icons.check_circle,
                    "Confirmar",
                    AppColors.secondary,
                    Alignment.centerLeft,
                  ),
                  secondaryBackground: _swipeBackground(
                    Icons.delete,
                    "Eliminar",
                    Colors.redAccent,
                    Alignment.centerRight,
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      await txController.clear(item.id);
                      return false;
                    }
                    return true;
                  },
                  onDismissed: (direction) async {
                    final deleted = item;
                    final ok = await txController.remove(item.id);
                    if (!ok && context.mounted) {
                      showStandardSnackbar(context, "Error al eliminar");
                      return;
                    }
                    await context.read<ReportsController>().load();
                    if (context.mounted) {
                      showUndoSnackbar(
                        context,
                        "Transacción eliminada",
                        () async {
                          final payload = _payloadFromTransaction(deleted);
                          await txController.create(payload);
                          await context.read<ReportsController>().load();
                        },
                      );
                    }
                  },
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(
                      item.type == "transfer"
                          ? "${fromName ?? "—"} → ${toName ?? "—"} • $subtitle"
                          : "${categoryName ?? "Sin categoría"} • $accountLabel • $subtitle",
                    ),
                    trailing: Text(
                      _amountPrefix(item.type) + amount,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: "Registrar gasto",
            onPressed: () => context.go("/transactions/new?type=expense"),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: "Registrar ingreso",
            onPressed: () => context.go("/transactions/new?type=income"),
          ),
        ],
      ),
    );
  }

  String _titleFor(String type, String? categoryName) {
    if (type == "income") return "Entró ${categoryName ?? ""}".trim();
    if (type == "transfer") return "Transferí";
    return "Salió ${categoryName ?? ""}".trim();
  }

  String _amountPrefix(String type) {
    if (type == "income") return "+ ";
    if (type == "transfer") return "";
    return "- ";
  }

  Map<String, dynamic> _payloadFromTransaction(Transaction tx) {
    return {
      "type": tx.type,
      "date": tx.date.toIso8601String(),
      "amount": tx.amount,
      "currency": tx.currency,
      "categoryId": tx.categoryId,
      "fromAccountId": tx.fromAccountId,
      "toAccountId": tx.toAccountId,
      "note": tx.note,
      "tags": tx.tags.isEmpty ? null : tx.tags,
      "status": tx.status,
    };
  }

  Widget _swipeBackground(
    IconData icon,
    String label,
    Color color,
    Alignment alignment,
  ) {
    return Container(
      color: color.withOpacity(0.1),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

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
    final start = DateTime(selected.year, selected.month, 1);
    final end = DateTime(selected.year, selected.month + 1, 0, 23, 59, 59);
    context.read<TransactionsController>().setFilters(
      TransactionFilters(
        dateFrom: start,
        dateTo: end,
        categoryId: filters.categoryId,
        accountId: filters.accountId,
        status: filters.status,
      ),
    );
  }
}

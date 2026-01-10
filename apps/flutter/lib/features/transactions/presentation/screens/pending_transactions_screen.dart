import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ownfinances/core/presentation/components/buttons.dart';
import 'package:ownfinances/core/theme/app_theme.dart';
import 'package:ownfinances/core/utils/formatters.dart';
import 'package:ownfinances/features/transactions/application/controllers/pending_transactions_controller.dart';
import 'package:intl/intl.dart';

class PendingTransactionsScreen extends StatefulWidget {
  const PendingTransactionsScreen({super.key});

  @override
  State<PendingTransactionsScreen> createState() => _PendingTransactionsScreenState();
}

class _PendingTransactionsScreenState extends State<PendingTransactionsScreen> {
  String _groupBy = 'category'; // 'category' or 'rule'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PendingTransactionsController>().loadPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PendingTransactionsController>();
    final state = controller.state;

    final totalAmount = state.items.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transações Pendentes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filters bottom sheet (Phase 2 enhancement)
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        "Nenhuma transação pendente",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        "Todas as recorrências foram confirmadas!",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${state.items.length} transaç${state.items.length > 1 ? 'ões' : 'ão'} pendente${state.items.length > 1 ? 's' : ''}",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                formatMoney(totalAmount),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: totalAmount < 0
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PrimaryButton(
                            label: "Confirmar tudo",
                            onPressed: () async {
                              final confirmed = await controller.confirmAll();
                              if (confirmed && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Confirmadas ${state.items.length} transações",
                                    ),
                                  ),
                                );
                                context.pop();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    // Group by toggle
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          const Text("Agrupar por:"),
                          const SizedBox(width: AppSpacing.sm),
                          ChoiceChip(
                            label: const Text("Categoria"),
                            selected: _groupBy == 'category',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _groupBy = 'category');
                              }
                            },
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ChoiceChip(
                            label: const Text("Recorrência"),
                            selected: _groupBy == 'rule',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _groupBy = 'rule');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    // Transactions list
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final transaction = state.items[index];
                          return Dismissible(
                            key: Key(transaction.id),
                            background: Container(
                              color: Colors.green,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                // Confirm
                                return await controller.confirmSingle(transaction.id);
                              } else {
                                // Delete
                                return await controller.deleteSingle(transaction.id);
                              }
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    transaction.type == 'expense'
                                        ? Colors.red.shade100
                                        : Colors.green.shade100,
                                child: Icon(
                                  transaction.type == 'expense'
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: transaction.type == 'expense'
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              title: Text(transaction.note ?? "Sem descrição"),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy').format(transaction.date),
                              ),
                              trailing: Text(
                                formatMoney(transaction.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: transaction.type == 'expense'
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              onTap: () {
                                // TODO: Navigate to edit transaction (optional)
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

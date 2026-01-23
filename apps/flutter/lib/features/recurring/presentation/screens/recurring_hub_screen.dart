import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ownfinances/core/presentation/components/buttons.dart';
import 'package:ownfinances/core/utils/formatters.dart';
import 'package:ownfinances/features/recurring/application/controllers/recurring_controller.dart';
import 'package:ownfinances/features/transactions/application/controllers/pending_transactions_controller.dart';
import 'package:ownfinances/features/recurring/domain/entities/recurring_rule.dart';

class RecurringHubScreen extends StatefulWidget {
  const RecurringHubScreen({super.key});

  @override
  State<RecurringHubScreen> createState() => _RecurringHubScreenState();
}

class _RecurringHubScreenState extends State<RecurringHubScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recorrências"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<RecurringController>().load();
              context.read<PendingTransactionsController>().loadPending();
            },
          ),
        ],
      ),
      body: const RecurringHubView(),
    );
  }
}

class RecurringHubView extends StatefulWidget {
  const RecurringHubView({super.key});

  @override
  State<RecurringHubView> createState() => _RecurringHubViewState();
}

class _RecurringHubViewState extends State<RecurringHubView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final recurringParams = context.read<RecurringController>();
    recurringParams.load(); // Load rules
    recurringParams.loadPendingSummary(); // "To Generate" count

    // Load pending (to confirm) transactions
    context.read<PendingTransactionsController>().loadPending();
  }

  void _openPlanner() {
    context.push('/recurring/plan');
  }

  @override
  Widget build(BuildContext context) {
    // Connect to state
    final recurringState = context.watch<RecurringController>().state;
    final pendingTxState = context.watch<PendingTransactionsController>().state;

    final rules = recurringState.items;
    final isLoading = recurringState.isLoading;

    final pendingCount = pendingTxState.items.length;
    final toGenerateCount = recurringState.toGenerateCount;

    // Split rules
    final activeRules = rules.where((r) => r.active).toList();
    final inactiveRules = rules.where((r) => !r.active).toList();

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Header & CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Contas fixas",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "O app só registra. Não cobra.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              PrimaryButton(
                label: "Nova",
                fullWidth: false,
                onPressed: () => context.push('/recurring/new'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Plan Month Card
          _buildPlanMonthCard(toGenerateCount, isLoading),
          const SizedBox(height: 16),

          // 3. Pending Confirm Card (Conditional)
          if (pendingCount > 0) ...[
            _buildPendingCard(pendingCount),
            const SizedBox(height: 16),
          ],

          const Divider(height: 32),

          // 4. My Rules List
          Text("Minhas regras", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          if (isLoading && rules.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (rules.isEmpty)
            _buildEmptyState()
          else ...[
            if (activeRules.isNotEmpty) ...[
              ...activeRules.map((r) => _RecurrenceRuleTile(rule: r)),
            ],

            if (inactiveRules.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  "Inativas",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...inactiveRules.map((r) => _RecurrenceRuleTile(rule: r)),
            ],
          ],

          const SizedBox(height: 80), // Fab space/Safe area
        ],
      ),
    );
  }

  Widget _buildPlanMonthCard(int toGenerate, bool isLoading) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Planejar mês",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Gere os lançamentos do mês a partir das regras.",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openPlanner,
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Abrir planejador"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(int count) {
    return Card(
      elevation: 0,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Confirmação pendente",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  Text("Você tem $count itens para confirmar."),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/transactions/pending'),
              child: const Text("Ver"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.rule, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Crie uma recorrência para planejar seu mês em segundos.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: "Nova recorrência",
            onPressed: () => context.push('/recurring/new'),
          ),
        ],
      ),
    );
  }
}

class _RecurrenceRuleTile extends StatelessWidget {
  final RecurringRule rule;

  const _RecurrenceRuleTile({required this.rule});

  @override
  Widget build(BuildContext context) {
    final note = rule.template.note;
    final title = (note != null && note.isNotEmpty) ? note : "Regra sem nome";
    final isExpense = rule.template.type == 'expense';

    // Format description logic: "Todo mês dia X"
    String frequencyDesc = "";
    if (rule.frequency == 'monthly') {
      final day = rule.startDate.day;
      frequencyDesc = "Todo mês dia $day";
    } else {
      frequencyDesc = rule.frequency == 'weekly' ? 'Semanal' : 'Anual';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isExpense
              ? Colors.red.shade50
              : Colors.green.shade50,
          child: Icon(
            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
            color: isExpense ? Colors.red : Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: !rule.active ? TextDecoration.lineThrough : null,
            color: !rule.active ? Colors.grey : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text("$frequencyDesc • ${formatMoney(rule.template.amount)}"),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit (stub for now, maybe route to wizard with ID?)
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text("Editar"),
                  onPressed: () {
                    // TODO: Navigate to edit
                    // context.push('/recurring/edit/${rule.id}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Edição em breve")),
                    );
                  },
                ),
                TextButton.icon(
                  icon: Icon(
                    rule.active ? Icons.pause : Icons.play_arrow,
                    size: 16,
                    color: rule.active ? Colors.orange : Colors.green,
                  ),
                  label: Text(rule.active ? "Pausar" : "Ativar"),
                  onPressed: () {
                    // Requires update method in Controller.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Pausar/Ativar em breve")),
                    );
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text(
                    "Excluir",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Excluir regra?"),
                        content: const Text(
                          "Isso não apaga lançamentos já gerados.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => context.pop(false),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () => context.pop(true),
                            child: const Text("Excluir"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await context.read<RecurringController>().delete(rule.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

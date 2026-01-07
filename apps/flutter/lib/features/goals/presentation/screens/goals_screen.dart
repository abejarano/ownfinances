import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/goals/application/controllers/goals_controller.dart";
import "package:ownfinances/features/goals/domain/entities/goal.dart";
import "package:ownfinances/features/goals/domain/entities/goal_projection.dart";

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GoalsController>();
    final state = context.watch<GoalsController>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Metas"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go("/dashboard"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Tus metas",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.load,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator()),
            if (!state.isLoading)
              Expanded(
                child: ListView.separated(
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = state.items[index];
                    final projection = state.projections[goal.id];
                    return _GoalCard(
                      goal: goal,
                      projection: projection,
                      onAdd: () => _openContributionForm(context, goal),
                      onEdit: () =>
                          _openGoalWizard(context, controller, goal: goal),
                      onDelete: () async {
                        final error = await controller.remove(goal.id);
                        if (error != null && context.mounted) {
                          showStandardSnackbar(context, error);
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openGoalWizard(context, controller),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openGoalWizard(
    BuildContext context,
    GoalsController controller, {
    Goal? goal,
  }) async {
    final nameController = TextEditingController(text: goal?.name ?? "");
    final targetController = TextEditingController(
      text: goal?.targetAmount != null ? formatMoney(goal!.targetAmount) : "",
    );
    final monthlyController = TextEditingController(
      text: goal?.monthlyContribution != null
          ? formatMoney(goal!.monthlyContribution!)
          : "",
    );
    DateTime startDate = goal?.startDate ?? DateTime.now();
    DateTime? targetDate = goal?.targetDate;
    String? accountId = goal?.linkedAccountId;

    final accounts = context.read<AccountsController>().state.items;
    final accountItems = accounts
        .map((acc) => PickerItem(id: acc.id, label: acc.name))
        .toList();

    int step = 0;
    bool isSaving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final suggested = _suggestedMonthly(
              targetController.text,
              targetDate,
              startDate,
            );
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal == null ? "Nueva meta" : "Editar meta",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (step == 0) ...[
                    Text(
                      "Para que es?",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nombre de la meta",
                      ),
                    ),
                  ],
                  if (step == 1) ...[
                    Text(
                      "Cuanto quieres juntar?",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MoneyInput(
                      label: "Monto objetivo",
                      controller: targetController,
                    ),
                  ],
                  if (step == 2) ...[
                    Text(
                      "Para cuando?",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Fecha objetivo (opcional)"),
                      subtitle: Text(
                        targetDate == null
                            ? "Sin fecha"
                            : formatDate(targetDate!),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: targetDate ?? startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setState(() => targetDate = selected);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (suggested != null)
                      Text(
                        "Sugerido: ${formatMoney(suggested)} por mes",
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    MoneyInput(
                      label: "Aporte mensual (opcional)",
                      controller: monthlyController,
                    ),
                  ],
                  if (step == 3) ...[
                    Text(
                      "Desde que cuenta ahorras?",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (accountItems.isEmpty)
                      const Text("No tienes cuentas activas.")
                    else
                      AccountPicker(
                        label: "Cuenta (opcional)",
                        items: accountItems,
                        value: accountId,
                        onSelected: (item) =>
                            setState(() => accountId = item.id),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: "Cancelar",
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (step > 0)
                        Expanded(
                          child: SecondaryButton(
                            label: "Atras",
                            onPressed: () => setState(() => step -= 1),
                          ),
                        ),
                      if (step > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          label: step == 3 ? "Guardar" : "Listo",
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (step < 3) {
                                    setState(() => step += 1);
                                    return;
                                  }

                                  final name = nameController.text.trim();
                                  final targetAmount =
                                      parseMoney(targetController.text.trim());
                                  final monthlyAmount =
                                      parseMoney(monthlyController.text.trim());

                                  if (name.isEmpty) {
                                    showStandardSnackbar(
                                      context,
                                      "Falta el nombre",
                                    );
                                    return;
                                  }
                                  if (targetAmount <= 0) {
                                    showStandardSnackbar(
                                      context,
                                      "El monto debe ser mayor que 0",
                                    );
                                    return;
                                  }

                                  setState(() => isSaving = true);
                                  String? error;
                                  if (goal == null) {
                                    error = await controller.create(
                                      name: name,
                                      targetAmount: targetAmount,
                                      currency: "BRL",
                                      startDate: startDate,
                                      targetDate: targetDate,
                                      monthlyContribution: monthlyAmount > 0
                                          ? monthlyAmount
                                          : null,
                                      linkedAccountId: accountId,
                                      isActive: true,
                                    );
                                  } else {
                                    error = await controller.update(
                                      id: goal.id,
                                      name: name,
                                      targetAmount: targetAmount,
                                      startDate: startDate,
                                      targetDate: targetDate,
                                      monthlyContribution: monthlyAmount > 0
                                          ? monthlyAmount
                                          : null,
                                      linkedAccountId: accountId,
                                      isActive: goal.isActive,
                                    );
                                  }
                                  setState(() => isSaving = false);

                                  if (error != null) {
                                    showStandardSnackbar(context, error);
                                    return;
                                  }
                                  if (context.mounted) {
                                    Navigator.of(context).pop(true);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true) return;
  }

  double? _suggestedMonthly(
    String targetRaw,
    DateTime? targetDate,
    DateTime startDate,
  ) {
    final targetAmount = parseMoney(targetRaw.trim());
    if (targetAmount <= 0 || targetDate == null) return null;
    final months =
        (targetDate.year * 12 + targetDate.month) -
        (startDate.year * 12 + startDate.month);
    if (months <= 0) return null;
    return targetAmount / months;
  }

  Future<void> _openContributionForm(BuildContext context, Goal goal) async {
    final controller = context.read<GoalsController>();
    final accountsState = context.read<AccountsController>().state;
    final accountItems = accountsState.items
        .map((acc) => PickerItem(id: acc.id, label: acc.name))
        .toList();

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime date = DateTime.now();
    String? accountId =
        controller.state.lastAccountId ??
        (accountItems.isNotEmpty ? accountItems.first.id : null);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Registrar aporte",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MoneyInput(label: "Monto", controller: amountController),
                  const SizedBox(height: AppSpacing.sm),
                  if (accountItems.isEmpty)
                    const Text("No tienes cuentas activas.")
                  else
                    AccountPicker(
                      label: "Cuenta",
                      items: accountItems,
                      value: accountId,
                      onSelected: (item) => setState(() => accountId = item.id),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Fecha"),
                    subtitle: Text(formatDate(date)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) {
                        setState(() => date = selected);
                      }
                    },
                  ),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: "Nota (opcional)",
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: "Guardar",
                    onPressed: accountItems.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true) return;

    final amount = parseMoney(amountController.text.trim());
    if (amount <= 0) {
      if (context.mounted) {
        showStandardSnackbar(context, "El monto debe ser mayor que 0");
      }
      return;
    }

    final error = await controller.createContribution(
      goalId: goal.id,
      date: date,
      amount: amount,
      accountId: accountId,
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
    );

    if (error != null && context.mounted) {
      showStandardSnackbar(context, error);
    }
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final GoalProjection? projection;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.projection,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = projection?.progress ?? 0;
    final target = goal.targetAmount;
    final ratio = target <= 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);
    final remaining = projection?.remaining ?? (target - progress);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.2),
            AppColors.primary.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "${formatMoney(progress)} / ${formatMoney(target)}",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: Colors.white12,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Restante ${formatMoney(remaining)}",
              style: const TextStyle(color: AppColors.muted),
            ),
            if (projection?.monthlyContributionSuggested != null)
              Text(
                "Sugerido ${formatMoney(projection!.monthlyContributionSuggested!)} / mes",
                style: const TextStyle(color: AppColors.muted),
              ),
            if (projection?.targetDateEstimated != null)
              Text(
                "Fecha estimada ${formatDate(projection!.targetDateEstimated!)}",
                style: const TextStyle(color: AppColors.muted),
              ),
            if (goal.targetDate != null)
              Text(
                "Meta ${formatDate(goal.targetDate!)}",
                style: const TextStyle(color: AppColors.muted),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: "Registrar aporte",
                    onPressed: onAdd,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SecondaryButton(
                    label: "Ver detalles",
                    onPressed: onEdit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

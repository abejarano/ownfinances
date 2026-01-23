import "package:flutter/material.dart";
import "package:provider/provider.dart";

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
    return Scaffold(
      appBar: AppBar(title: const Text("Metas")),
      body: const GoalsView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => GoalsView.openWizard(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GoalsView extends StatelessWidget {
  const GoalsView({super.key});

  static Future<void> openWizard(BuildContext context) async {
    // Find the instance to call the method?
    // Actually _openGoalWizard needs the controller.
    // We can make a static helper or just instantiate a temporary GoalsView to access private methods?
    // Better: make _openGoalWizard static or move it out.
    // Or just duplicate the FAB logic in the wrapper.
    // But we want to move FAB to inline button.

    // So let's just use the View's logic.
    final controller = context.read<GoalsController>();
    // We need to move _openGoalWizard to be a static method or mixin or just accessible.
    // Since I am editing the file, I will change _openGoalWizard to be static or public.
    await _openGoalWizard(context, controller);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GoalsController>();
    final state = context.watch<GoalsController>().state;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Suas metas",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.load,
              ),
              const SizedBox(width: 8),
              PrimaryButton(
                label: "Nova meta",
                fullWidth: false,
                onPressed: () => _openGoalWizard(context, controller),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.isLoading) const Center(child: CircularProgressIndicator()),
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
                    onQuickAdd: () =>
                        _quickContribution(context, goal, projection),
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
    );
  }

  static Future<void> _openGoalWizard(
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
                    goal == null ? "Nova meta" : "Editar meta",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (step == 0) ...[
                    Text(
                      "Criar meta",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nome da meta",
                        hintText: "Ex: Fundo de emergência",
                      ),
                      autofocus: goal == null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MoneyInput(
                      label: "Valor alvo",
                      controller: targetController,
                    ),
                  ],
                  if (step == 1) ...[
                    Text(
                      "Detalhes (opcional)",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Data alvo (opcional)"),
                      subtitle: Text(
                        targetDate == null
                            ? "Sem data"
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
                    const SizedBox(height: AppSpacing.md),
                    if (suggested != null)
                      Text(
                        "Sugerido: ${formatMoney(suggested)} por mes",
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    MoneyInput(
                      label: "Aporte mensal (opcional)",
                      controller: monthlyController,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (accountItems.isNotEmpty)
                      AccountPicker(
                        label: "Conta vinculada (opcional)",
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
                            label: "Voltar",
                            onPressed: () => setState(() => step -= 1),
                          ),
                        ),
                      if (step > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PrimaryButton(
                          label: step == 0 ? "Continuar" : "Salvar",
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  final targetAmount = parseMoney(
                                    targetController.text.trim(),
                                  );
                                  final monthlyAmount = parseMoney(
                                    monthlyController.text.trim(),
                                  );

                                  // Validar mínimos
                                  if (name.isEmpty) {
                                    showStandardSnackbar(
                                      context,
                                      "Falta o nome",
                                    );
                                    return;
                                  }
                                  if (targetAmount <= 0) {
                                    showStandardSnackbar(
                                      context,
                                      "O valor deve ser maior que 0",
                                    );
                                    return;
                                  }

                                  // Si estamos en paso 0, avanzar al paso 1
                                  if (step == 0) {
                                    setState(() => step += 1);
                                    return;
                                  }

                                  // Si estamos en paso 1, guardar
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

  static double? _suggestedMonthly(
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

  static Future<void> _openContributionForm(
    BuildContext context,
    Goal goal,
  ) async {
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
                  const SizedBox(height: AppSpacing.md),
                  MoneyInput(label: "Valor", controller: amountController),
                  const SizedBox(height: AppSpacing.md),
                  if (accountItems.isEmpty)
                    const Text("Voce nao tem contas ativas.")
                  else
                    AccountPicker(
                      label: "Conta",
                      items: accountItems,
                      value: accountId,
                      onSelected: (item) => setState(() => accountId = item.id),
                    ),
                  const SizedBox(height: AppSpacing.md),
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
                    label: "Salvar",
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
        showStandardSnackbar(context, "O valor deve ser maior que 0");
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

  static Future<void> _quickContribution(
    BuildContext context,
    Goal goal,
    GoalProjection? projection,
  ) async {
    final controller = context.read<GoalsController>();
    final accountsState = context.read<AccountsController>().state;
    final accountItems = accountsState.items
        .map((acc) => PickerItem(id: acc.id, label: acc.name))
        .toList();

    // Determinar valor sugerido
    final suggestedAmount =
        goal.monthlyContribution ?? projection?.monthlyContributionSuggested;
    if (suggestedAmount == null || suggestedAmount <= 0) {
      if (context.mounted) {
        showStandardSnackbar(
          context,
          "Configure um aporte mensal para usar aporte rápido",
        );
      }
      return;
    }

    // Determinar cuenta por defecto
    String? accountId =
        controller.state.lastAccountId ??
        goal.linkedAccountId ??
        (accountItems.isNotEmpty ? accountItems.first.id : null);

    if (accountId == null) {
      if (context.mounted) {
        showStandardSnackbar(
          context,
          "Configure uma conta para usar aporte rápido",
        );
      }
      return;
    }

    // Crear aporte directamente
    final error = await controller.createContribution(
      goalId: goal.id,
      date: DateTime.now(),
      amount: suggestedAmount,
      accountId: accountId,
      note: null,
    );

    if (error != null && context.mounted) {
      showStandardSnackbar(context, error);
    } else if (context.mounted) {
      showStandardSnackbar(
        context,
        "Aporte de ${formatMoney(suggestedAmount)} registrado",
      );
    }
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final GoalProjection? projection;
  final VoidCallback onAdd;
  final VoidCallback? onQuickAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.projection,
    required this.onAdd,
    this.onQuickAdd,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildProjectionText() {
    final monthlyContribution =
        goal.monthlyContribution ?? projection?.monthlyContributionSuggested;
    final targetDate = goal.targetDate ?? projection?.targetDateEstimated;

    if (monthlyContribution != null &&
        monthlyContribution > 0 &&
        targetDate != null) {
      // Caso ideal: tiene aporte mensal y fecha alvo
      return Text(
        "Se guardar ${formatMoney(monthlyContribution)}/mês, chega em ${formatDate(targetDate)}.",
        style: const TextStyle(color: AppColors.muted),
      );
    } else if (monthlyContribution != null && monthlyContribution > 0) {
      // Tiene aporte mensal pero no fecha alvo
      if (projection?.targetDateEstimated != null) {
        return Text(
          "Guardando ${formatMoney(monthlyContribution)}/mês, chega em ${formatDate(projection!.targetDateEstimated!)}.",
          style: const TextStyle(color: AppColors.muted),
        );
      }
      return Text(
        "Guardando ${formatMoney(monthlyContribution)}/mês",
        style: const TextStyle(color: AppColors.muted),
      );
    } else if (targetDate != null) {
      // Tiene fecha alvo pero no aporte mensal
      if (projection?.monthlyContributionSuggested != null) {
        return Text(
          "Para chegar em ${formatDate(targetDate)}, precisa guardar ${formatMoney(projection!.monthlyContributionSuggested!)}/mês.",
          style: const TextStyle(color: AppColors.muted),
        );
      }
      return Text(
        "Meta ${formatDate(targetDate)}",
        style: const TextStyle(color: AppColors.muted),
      );
    }

    // Sin aporte mensal ni fecha alvo
    return const SizedBox.shrink();
  }

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
            _buildProjectionText(),
            const SizedBox(height: AppSpacing.sm),
            if (onQuickAdd != null &&
                (goal.monthlyContribution != null ||
                    projection?.monthlyContributionSuggested != null)) ...[
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: "Aporte rápido",
                      onPressed: onQuickAdd,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SecondaryButton(
                      label: "Personalizar",
                      onPressed: onAdd,
                    ),
                  ),
                ],
              ),
            ] else ...[
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
                      label: "Ver detalhes",
                      onPressed: onEdit,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/cards.dart";
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/utils/formatters.dart";

class UiKitScreen extends StatefulWidget {
  const UiKitScreen({super.key});

  @override
  State<UiKitScreen> createState() => _UiKitScreenState();
}

class _UiKitScreenState extends State<UiKitScreen> {
  final TextEditingController _moneyController = TextEditingController();
  String? _selectedCategory;
  String? _selectedAccount;

  final List<PickerItem> _categories = const [
    PickerItem(id: "food", label: "Alimentacao"),
    PickerItem(id: "transport", label: "Transporte"),
    PickerItem(id: "health", label: "Saude"),
  ];

  final List<PickerItem> _accounts = const [
    PickerItem(id: "wallet", label: "Carteira"),
    PickerItem(id: "bank", label: "Banco"),
    PickerItem(id: "card", label: "Cartao"),
  ];

  @override
  void dispose() {
    _moneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("UI Kit")),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text("Copy", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const Text("Pendiente / Confirmado"),
          const SizedBox(height: AppSpacing.sm),
          Text("Hoje: ${formatDate(DateTime.now())}"),
          const SizedBox(height: AppSpacing.lg),
          Text("Botoes", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: "Registrar gasto",
            onPressed: () {
              showStandardSnackbar(
                context,
                "Gasto registrado. Te quedan R\$ 120 en Alimentacao este mes.",
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: "Transferir",
            onPressed: () {
              showUndoSnackbar(
                context,
                "Transferencia eliminada.",
                () {},
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text("Inputs", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          MoneyInput(label: "Valor", controller: _moneyController),
          const SizedBox(height: AppSpacing.sm),
          CategoryPicker(
            label: "Categoria",
            items: _categories,
            value: _selectedCategory,
            onSelected: (item) => setState(() => _selectedCategory = item.id),
          ),
          const SizedBox(height: AppSpacing.sm),
          AccountPicker(
            label: "Conta",
            items: _accounts,
            value: _selectedAccount,
            onSelected: (item) => setState(() => _selectedAccount = item.id),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text("Cards", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          QuickActionCard(
            icon: Icons.arrow_downward,
            title: "Registrar gasto",
            subtitle: "Saiu ${formatMoney(98.5)}",
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          InlineSummaryCard(
            title: "Marco",
            planned: formatMoney(1200),
            actual: formatMoney(980.5),
            remaining: formatMoney(219.5),
          ),
        ],
      ),
    );
  }
}

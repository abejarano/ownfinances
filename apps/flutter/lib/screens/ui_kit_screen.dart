import "package:flutter/material.dart";
import "package:ownfinances/core/presentation/components/buttons.dart";
import "package:ownfinances/core/presentation/components/cards.dart";
import "package:ownfinances/core/presentation/components/money_input.dart";
import "package:ownfinances/core/presentation/components/pickers.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";

class UiKitScreen extends StatefulWidget {
  const UiKitScreen({super.key});

  @override
  State<UiKitScreen> createState() => _UiKitScreenState();
}

class _UiKitScreenState extends State<UiKitScreen> {
  final TextEditingController _moneyController = TextEditingController();
  String? category;
  String? account;

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
          PrimaryButton(label: "Guardar", onPressed: () {}),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(label: "Listo", onPressed: () {}),
          const SizedBox(height: AppSpacing.md),
          MoneyInput(label: "Monto", controller: _moneyController),
          const SizedBox(height: AppSpacing.md),
          CategoryPicker(
            label: "Categoría",
            items: const ["Comida", "Transporte", "Salud", "Ocio"],
            value: category,
            onSelected: (value) => setState(() => category = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AccountPicker(
            label: "Cuenta",
            items: const ["Nubank", "Wallet", "Banco"],
            value: account,
            onSelected: (value) => setState(() => account = value),
          ),
          const SizedBox(height: AppSpacing.md),
          QuickActionCard(
            icon: Icons.receipt_long,
            title: "Registrar gasto",
            subtitle: "Salió R\$ 0,00",
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          const InlineSummaryCard(
            title: "Resumo",
            planned: "R\$ 1.500,00",
            actual: "R\$ 900,00",
            remaining: "R\$ 600,00",
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () =>
                showUndoSnackbar(context, "Transacción eliminada", () {}),
            child: const Text("Mostrar Snackbar"),
          ),
        ],
      ),
    );
  }
}

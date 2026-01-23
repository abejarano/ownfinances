import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/settings/application/controllers/settings_controller.dart";
import "package:ownfinances/core/utils/currency_utils.dart";

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoGenerateRecurring = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final apiClient = context.read<ApiClient>();
      final result = await apiClient.get('/settings');
      setState(() {
        _autoGenerateRecurring =
            result['autoGenerateRecurring'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAutoGenerate(bool value) async {
    setState(() {
      _autoGenerateRecurring = value;
    });

    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.put('/settings', {'autoGenerateRecurring': value});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Configuração salva com sucesso!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _autoGenerateRecurring = !value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao atualizar configuração: $e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // 0. Gerenciar Shortcut (Moved Management here)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.grid_view,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Gerenciar",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Categorias, contas, dívidas e metas ficam no menu.",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      return OutlinedButton(
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                        child: const Text("Abrir menu"),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 1. Preferências Section
        _buildSectionTitle(context, "Preferências"),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              Consumer<SettingsController>(
                builder: (context, settings, child) {
                  return ListTile(
                    leading: const Icon(
                      Icons.monetization_on_outlined,
                      color: AppColors.textTertiary,
                    ),
                    title: const Text("Moeda principal"),
                    subtitle: const Text(
                      "O Resumo do mês usa apenas esta moeda. Outras moedas aparecem nas contas (sem conversão).",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyUtils.formatCurrencyLabel(
                            settings.primaryCurrency,
                          ),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                    onTap: () => _showCurrencyPicker(context, settings),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. Automação Section (Updated Copy)
        _buildSectionTitle(context, "Automação"),
        const SizedBox(height: AppSpacing.sm),
        Card(
          // Uses standard SURFACE-1 from theme
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Gerar automaticamente"),
                subtitle: const Text(
                  "Cria lançamentos de contas fixas ao iniciar o mês (não movimenta dinheiro).",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                value: _autoGenerateRecurring,
                onChanged: _isLoading ? null : _updateAutoGenerate,
                activeColor: Colors.white,
                activeTrackColor: AppColors.success,
                tileColor: Colors.transparent, // Uses card background
              ),
              if (_autoGenerateRecurring)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.info),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "As transações serão criadas como pendentes na data prevista.",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 3. Conta Section
        _buildSectionTitle(context, "Conta"),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text(
                  "Sair",
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () async {
                  await context.read<AuthController>().logout();
                  if (context.mounted) {
                    context.go("/login");
                  }
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              const ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: AppColors.textTertiary,
                ),
                title: Text("Versão"),
                trailing: Text(
                  "1.0.0",
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _showCurrencyPicker(
    BuildContext context,
    SettingsController controller,
  ) async {
    final current = controller.primaryCurrency;
    final pickerOptions = ["BRL", "COP", "VES", "USD", "EUR", "GBP", "USDT"];

    // Check if current is custom (not in options)
    final isCustom = !pickerOptions.contains(current);
    final customController = TextEditingController(
      text: isCustom ? current : "",
    );
    String? selected = isCustom ? "OTHER" : current;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Moeda principal"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...pickerOptions.map(
                      (opt) => RadioListTile<String>(
                        title: Text(CurrencyUtils.formatCurrencyLabel(opt)),
                        value: opt,
                        groupValue: selected,
                        onChanged: (val) {
                          setState(() => selected = val);
                        },
                        activeColor: AppColors.primary,
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text("Outra"),
                      value: "OTHER",
                      groupValue: selected,
                      onChanged: (val) {
                        setState(() => selected = val);
                      },
                      activeColor: AppColors.primary,
                    ),
                    if (selected == "OTHER")
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: customController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: "Código (ex: COP)",
                            hintText: "3-5 letras maiúsculas",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}), // Refresh for val
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () {
                    String finalVal = selected!;
                    if (selected == "OTHER") {
                      finalVal = customController.text.trim().toUpperCase();
                      // Validation: 3-5 chars, A-Z only
                      if (!RegExp(r'^[A-Z]{3,5}$').hasMatch(finalVal)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Código inválido. Use 3 a 5 letras (A-Z).",
                            ),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                    }
                    controller.setPrimaryCurrency(finalVal);
                    Navigator.pop(context);
                  },
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

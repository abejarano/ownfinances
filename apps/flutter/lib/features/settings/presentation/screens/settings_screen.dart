import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/core/theme/app_theme.dart";
import "package:ownfinances/core/infrastructure/api/api_client.dart";

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
          SnackBar(
            content: Text(
              value
                  ? "Auto-geração ativada! Recorrências serão geradas automaticamente."
                  : "Auto-geração desativada.",
            ),
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
        Text(
          "Configurações",
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 1. Recorrências Section
        _buildSectionTitle(context, "Automação"),
        const SizedBox(height: AppSpacing.sm),
        Card(
          // Uses standard SURFACE-1 from theme
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Gerar automaticamente"),
                subtitle: const Text(
                  "Gera recorrências do mês ao abrir o app pela primeira vez.",
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
                          "As transações serão criadas como pendentes.",
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

        // 2. Gestão Section
        _buildSectionTitle(context, "Gestão"),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              _buildNavTile(
                context,
                "Categorias",
                Icons.category_outlined,
                "/categories",
              ),
              const Divider(indent: 16, endIndent: 16),
              _buildNavTile(
                context,
                "Contas",
                Icons.account_balance_wallet_outlined,
                "/accounts",
              ),
              const Divider(indent: 16, endIndent: 16),
              _buildNavTile(
                context,
                "Dívidas",
                Icons.money_off_csred_outlined,
                "/debts",
              ),
              const Divider(indent: 16, endIndent: 16),
              _buildNavTile(context, "Metas", Icons.flag_outlined, "/goals"),
              const Divider(indent: 16, endIndent: 16),
              _buildNavTile(
                context,
                "Regras de Recorrência",
                Icons.restore_outlined,
                "/recurring",
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
                  "0.0.1",
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

  Widget _buildNavTile(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textTertiary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: () => context.push(route),
    );
  }
}

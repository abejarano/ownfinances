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
            backgroundColor: Colors.red,
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
        Text("Configuracoes", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),

        // Recorrências section
        Text("Recorrências", style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Gerar automaticamente"),
                subtitle: const Text(
                  "Gera todas as recorrências do mês automaticamente ao iniciar o app pela primeira vez no mês",
                ),
                value: _autoGenerateRecurring,
                onChanged: _isLoading ? null : _updateAutoGenerate,
              ),
              if (_autoGenerateRecurring)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "As transações serão criadas como pendentes. Você ainda precisará confirmá-las.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        const SizedBox(height: AppSpacing.md),
        Text("Gestão", style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          title: const Text("Categorias"),
          onTap: () => context.push("/categories"),
        ),
        ListTile(
          title: const Text("Contas"),
          onTap: () => context.push("/accounts"),
        ),
        ListTile(
          title: const Text("Dividas"),
          onTap: () => context.push("/debts"),
        ),
        ListTile(
          title: const Text("Metas"),
          onTap: () => context.push("/goals"),
        ),
        ListTile(
          title: const Text("Recorrências"),
          onTap: () => context.push("/recurring"),
        ),

        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text("Sair"),
          onTap: () async {
            await context.read<AuthController>().logout();
            if (context.mounted) {
              context.go("/login");
            }
          },
        ),
        const ListTile(title: Text("Versión"), subtitle: Text("0.0.1")),
      ],
    );
  }
}

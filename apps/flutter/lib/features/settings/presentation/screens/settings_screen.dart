import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/core/theme/app_theme.dart";

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text("Config", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text("Moneda"),
          subtitle: const Text("BRL (R\$)"),
          onTap: () {},
        ),
        ListTile(
          title: const Text("Periodo"),
          subtitle: const Text("Mensual"),
          onTap: () {},
        ),
        ListTile(
          title: const Text("Categorias"),
          onTap: () => context.go("/categories"),
        ),
        ListTile(
          title: const Text("Cuentas"),
          onTap: () => context.go("/accounts"),
        ),
        ListTile(
          title: const Text("Deudas"),
          onTap: () => context.go("/debts"),
        ),
        ListTile(
          title: const Text("Metas"),
          onTap: () => context.go("/goals"),
        ),
        ListTile(
          title: const Text("UI Kit"),
          onTap: () => context.go("/ui-kit"),
        ),
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

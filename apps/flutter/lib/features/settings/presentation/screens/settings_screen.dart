import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/core/theme/app_theme.dart";

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          title: const Text("Sair"),
          onTap: () async {
            await ref.read(authControllerProvider.notifier).logout();
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

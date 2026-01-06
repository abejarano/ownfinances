import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;
import "package:go_router/go_router.dart";
import "package:ownfinances/state/app_state.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/core/presentation/components/snackbar.dart";
import "package:ownfinances/core/theme/app_theme.dart";

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devMode = ref.watch(devModeProvider);

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
            await ref.read(authControllerProvider).logout();
            if (context.mounted) {
              context.go("/login");
            }
          },
        ),
        GestureDetector(
          onLongPress: () => ref.read(devModeProvider.notifier).state = true,
          child: const ListTile(
            title: Text("Versión"),
            subtitle: Text("0.0.1"),
          ),
        ),
        if (devMode) ...[
          const Divider(),
          const Text("Dev", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => context.go("/ui-kit"),
            child: const Text("UI Kit"),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: () async {
              const url = "http://localhost:3000/health";
              try {
                final res = await http.get(Uri.parse(url));
                final parsed = jsonDecode(res.body) as Map<String, dynamic>;
                if (context.mounted) {
                  showStandardSnackbar(context, "Ping OK: ${parsed["ok"]}");
                }
              } catch (_) {
                if (context.mounted) {
                  showStandardSnackbar(context, "Ping falló");
                }
              }
            },
            child: const Text("Ping API"),
          ),
        ],
      ],
    );
  }
}

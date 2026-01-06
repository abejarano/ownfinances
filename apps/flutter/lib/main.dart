import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:ownfinances/core/routing/app_router.dart";
import "package:ownfinances/core/theme/app_theme.dart";

void main() {
  runApp(const ProviderScope(child: OwnFinancesApp()));
}

class OwnFinancesApp extends ConsumerWidget {
  const OwnFinancesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: "OwnFinances",
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}

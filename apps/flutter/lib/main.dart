import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/screens/budget_screen.dart";
import "package:ownfinances/screens/dashboard_screen.dart";
import "package:ownfinances/screens/onboarding_screen.dart";
import "package:ownfinances/screens/settings_screen.dart";
import "package:ownfinances/screens/transactions_screen.dart";
import "package:ownfinances/screens/ui_kit_screen.dart";
import "package:ownfinances/state/app_state.dart";
import "package:ownfinances/ui/components/app_scaffold.dart";
import "package:ownfinances/ui/theme/app_theme.dart";

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

final routerProvider = Provider<GoRouter>((ref) {
  final completed = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    initialLocation: "/dashboard",
    redirect: (context, state) {
      final isOnboarding = state.fullPath == "/onboarding";
      if (!completed && !isOnboarding) {
        return "/onboarding";
      }
      if (completed && isOnboarding) {
        return "/dashboard";
      }
      return null;
    },
    routes: [
      GoRoute(
        path: "/onboarding",
        builder: (context, state) => OnboardingScreen(
          onStart: () {
            ref.read(onboardingCompletedProvider.notifier).state = true;
          },
        ),
      ),
      GoRoute(
        path: "/ui-kit",
        builder: (context, state) => const UiKitScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.toString();
          final currentIndex = _indexFromLocation(location);
          return AppScaffold(
            title: _titleFromLocation(location),
            currentIndex: currentIndex,
            onTap: (index) => _goToIndex(context, index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view),
                label: "Dashboard",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.swap_horiz),
                label: "Transacciones",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart),
                label: "Presupuesto",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: "Config",
              ),
            ],
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: "/dashboard",
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: "/transactions",
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: "/budget",
            builder: (context, state) => const BudgetScreen(),
          ),
          GoRoute(
            path: "/settings",
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

int _indexFromLocation(String location) {
  if (location.startsWith("/transactions")) return 1;
  if (location.startsWith("/budget")) return 2;
  if (location.startsWith("/settings")) return 3;
  return 0;
}

String _titleFromLocation(String location) {
  if (location.startsWith("/transactions")) return "Transacciones";
  if (location.startsWith("/budget")) return "Presupuesto";
  if (location.startsWith("/settings")) return "Config";
  return "Dashboard";
}

void _goToIndex(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go("/dashboard");
      return;
    case 1:
      context.go("/transactions");
      return;
    case 2:
      context.go("/budget");
      return;
    case 3:
      context.go("/settings");
      return;
  }
}

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/features/auth/presentation/screens/login_screen.dart";

import "package:ownfinances/features/auth/presentation/screens/register_screen.dart";
import "package:ownfinances/features/auth/presentation/screens/splash_screen.dart";
import "package:ownfinances/features/auth/application/state/auth_state.dart";
import "package:ownfinances/features/onboarding/presentation/screens/setup_wizard_screen.dart";
import "package:ownfinances/features/dashboard/presentation/screens/dashboard_screen.dart";
import "package:ownfinances/features/transactions/presentation/screens/transactions_screen.dart";
import "package:ownfinances/features/transactions/presentation/screens/transaction_form_screen.dart";
import "package:ownfinances/features/budgets/presentation/screens/budget_screen.dart";
import "package:ownfinances/features/settings/presentation/screens/settings_screen.dart";
import "package:ownfinances/features/categories/presentation/screens/categories_screen.dart";
import "package:ownfinances/features/accounts/presentation/screens/accounts_screen.dart";
import "package:ownfinances/features/recurring/presentation/screens/recurring_wizard_screen.dart";
import "package:ownfinances/features/templates/presentation/screens/template_list_screen.dart";
import "package:ownfinances/core/presentation/components/app_scaffold.dart";
import "package:ownfinances/features/templates/domain/entities/transaction_template.dart";
import "package:ownfinances/core/routing/onboarding_controller.dart";
import "package:ownfinances/features/ui_kit/presentation/screens/ui_kit_screen.dart";
import "package:ownfinances/features/debts/presentation/screens/debts_screen.dart";
import "package:ownfinances/features/goals/presentation/screens/goals_screen.dart";

GoRouter createRouter({
  required AuthController authController,
  required OnboardingController onboardingController,
}) {
  return GoRouter(
    initialLocation: "/login",
    refreshListenable: Listenable.merge([authController, onboardingController]),
    redirect: (context, state) {
      final location = state.uri.path;
      final isOnboarding = location == "/onboarding";
      final isAuthRoute = location == "/login" || location == "/register";
      final authStatus = authController.state.status;
      final isUnauthenticated = authStatus == AuthStatus.unauthenticated;
      final isAuthed = authStatus == AuthStatus.authenticated;
      final completed = onboardingController.completed;

      if (authStatus == AuthStatus.initial) {
        return "/splash";
      }

      if (location == "/splash" && authStatus != AuthStatus.initial) {
        return isAuthed ? "/dashboard" : "/login";
      }

      if (isUnauthenticated) {
        if (!isAuthRoute) {
          return "/login";
        }
        return null;
      }
      if (isAuthed && !completed) {
        if (!isOnboarding) {
          return "/onboarding";
        }
        return null;
      }
      if (isAuthed && completed && isOnboarding) {
        return "/dashboard";
      }
      if (isAuthed && completed && isAuthRoute) {
        return "/dashboard";
      }
      return null;
    },
    routes: [
      GoRoute(
        path: "/onboarding",
        builder: (context, state) => const SetupWizardScreen(),
      ),
      GoRoute(
        path: "/splash",
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: "/login", builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: "/register",
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: "/transactions/new",
        builder: (context, state) => TransactionFormScreen(
          initialType: state.uri.queryParameters["type"],
          initialTemplate: state.extra as TransactionTemplate?,
        ),
      ),
      GoRoute(
        path: "/categories",
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: "/accounts",
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: "/recurring/new",
        builder: (context, state) => const RecurringWizardScreen(),
      ),
      GoRoute(
        path: "/templates",
        builder: (context, state) => const TemplateListScreen(),
      ),
      GoRoute(
        path: "/ui-kit",
        builder: (context, state) => const UiKitScreen(),
      ),
      GoRoute(path: "/debts", builder: (context, state) => const DebtsScreen()),
      GoRoute(path: "/goals", builder: (context, state) => const GoalsScreen()),
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
}

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

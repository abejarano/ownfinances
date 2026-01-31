import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/features/auth/presentation/screens/login_screen.dart";

import "package:ownfinances/features/auth/presentation/screens/register_screen.dart";
import "package:ownfinances/features/auth/presentation/screens/splash_screen.dart";
import "package:ownfinances/features/auth/application/state/auth_state.dart";
import "package:ownfinances/features/onboarding/presentation/screens/setup_wizard_screen.dart";
import "package:ownfinances/features/dashboard/presentation/screens/dashboard_screen.dart";
import "package:ownfinances/features/voice_capture/voice_capture_screen.dart";
import "package:ownfinances/features/transactions/presentation/screens/transactions_screen.dart";
import "package:ownfinances/features/transactions/presentation/screens/transaction_form_screen.dart";
import "package:ownfinances/features/transactions/presentation/screens/pending_transactions_screen.dart";
import "package:ownfinances/features/budgets/presentation/screens/budget_screen.dart";
import "package:ownfinances/features/settings/presentation/screens/settings_screen.dart";
import "package:ownfinances/features/categories/presentation/screens/categories_screen.dart";
import "package:ownfinances/features/accounts/presentation/screens/accounts_screen.dart";
import "package:ownfinances/features/recurring/presentation/screens/recurring_wizard_screen.dart";
import "package:ownfinances/features/recurring/presentation/screens/recurring_plan_screen.dart";
import "package:ownfinances/features/recurring/presentation/screens/recurring_hub_screen.dart";
import "package:ownfinances/features/templates/presentation/screens/template_list_screen.dart";
import "package:ownfinances/core/presentation/components/app_scaffold.dart";
import "package:ownfinances/core/presentation/components/app_drawer.dart";
import "package:ownfinances/features/templates/domain/entities/transaction_template.dart";
import "package:ownfinances/features/transactions/domain/entities/transaction.dart";
import "package:ownfinances/core/routing/onboarding_controller.dart";

import "package:ownfinances/features/debts/presentation/screens/debts_screen.dart";
import "package:ownfinances/features/goals/presentation/screens/goals_screen.dart";
import "package:ownfinances/features/csv_import/presentation/screens/csv_import_wizard_screen.dart";
import "package:ownfinances/features/csv_import/presentation/screens/csv_import_success_screen.dart";
import "package:ownfinances/features/month_summary/presentation/screens/month_summary_screen.dart";
import "package:ownfinances/l10n/app_localizations.dart";

GoRouter createRouter({
  required AuthController authController,
  required OnboardingController onboardingController,
}) {
  return GoRouter(
    initialLocation: "/login",
    refreshListenable: Listenable.merge([authController, onboardingController]),
    redirect: (context, state) {
      final location = state.uri.path;
      final hasVoiceQuery =
          state.uri.queryParameters.containsKey("intent") ||
          state.uri.queryParameters.containsKey("feature");
      final isVoicePath = location == "/voice" || location == "/voice-capture";
      final isVoiceDeepLink =
          (state.uri.scheme == "desquadra" && state.uri.host == "voice") ||
          (isVoicePath && hasVoiceQuery) ||
          ((location == "/" || location.isEmpty) && hasVoiceQuery);
      final isOnboarding = location == "/onboarding";
      final isAuthRoute = location == "/login" || location == "/register";
      final authStatus = authController.state.status;
      final isUnauthenticated = authStatus == AuthStatus.unauthenticated;
      final isAuthed = authStatus == AuthStatus.authenticated;
      final completed = onboardingController.completed;
      final onboardingLoaded = onboardingController.loaded;

      if (authStatus == AuthStatus.initial) {
        if (isVoiceDeepLink) return null;
        return "/splash";
      }

      if (location == "/splash" && authStatus != AuthStatus.initial) {
        if (!isAuthed) return "/login";
      }

      if (isUnauthenticated) {
        if (!isAuthRoute) {
          return "/login";
        }
        return null;
      }

      if (isAuthed && !onboardingLoaded) {
        if (location != "/splash") return "/splash";
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
      if (isAuthed && completed && location == "/splash") {
        return "/dashboard";
      }
      if (isAuthed && completed && isVoiceDeepLink) {
        final params = Map<String, String>.from(state.uri.queryParameters);
        final feature = params["feature"];
        if (params["intent"] == null && feature != null) {
          final normalized = feature.toLowerCase();
          if (normalized.contains("expense") ||
              normalized.contains("despesa") ||
              normalized.contains("gasto")) {
            params["intent"] = "expense";
          }
        }
        params.remove("feature");
        params.putIfAbsent("source", () => "assistant");
        final uri = Uri(path: "/voice-capture", queryParameters: params);
        return uri.toString();
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
        path: "/voice-capture",
        builder: (context, state) => VoiceCaptureScreen(
          intent: state.uri.queryParameters["intent"],
          source: state.uri.queryParameters["source"],
        ),
      ),
      GoRoute(
        path: "/voice",
        builder: (context, state) => VoiceCaptureScreen(
          intent: state.uri.queryParameters["intent"],
          source: state.uri.queryParameters["source"],
        ),
      ),
      GoRoute(
        path: "/transactions/new",
        builder: (context, state) {
          final extra = state.extra;
          return TransactionFormScreen(
            initialType: state.uri.queryParameters["type"],
            initialTemplate: extra is TransactionTemplate ? extra : null,
            initialTransaction: extra is Transaction ? extra : null,
          );
        },
      ),
      GoRoute(
        path: "/transactions/edit",
        builder: (context, state) => TransactionFormScreen(
          initialTransaction: state.extra as Transaction?,
        ),
      ),
      GoRoute(
        path: "/transactions/pending",
        builder: (context, state) => const PendingTransactionsScreen(),
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
        path: "/recurring",
        builder: (context, state) => const RecurringHubScreen(),
      ),
      GoRoute(
        path: "/recurring/new",
        builder: (context, state) => const RecurringWizardScreen(),
      ),
      GoRoute(
        path: "/recurring/plan",
        builder: (context, state) => const RecurringPlanScreen(),
      ),
      GoRoute(
        path: "/templates",
        builder: (context, state) => const TemplateListScreen(),
      ),

      GoRoute(path: "/debts", builder: (context, state) => const DebtsScreen()),
      GoRoute(path: "/goals", builder: (context, state) => const GoalsScreen()),
      GoRoute(
        path: "/csv-import",
        builder: (context, state) => const CsvImportWizardScreen(),
      ),
      GoRoute(
        path: "/csv-import/success",
        builder: (context, state) => const CsvImportSuccessScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.toString();
          final currentIndex = _indexFromLocation(location);
          return Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return AppScaffold(
                title: _titleFromLocation(location, context),
                currentIndex: currentIndex,
                onTap: (index) => _goToIndex(context, index),
                drawer: const AppDrawer(),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.grid_view),
                    label: loc?.navDashboard ?? "Inicio",
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.swap_horiz),
                    label: loc?.navTransactions ?? "Transações",
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.pie_chart),
                    label: loc?.navBudgets ?? "Orçamentos",
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings),
                    label: loc?.navSettings ?? "Ajustes",
                  ),
                ],
                body: child,
              );
            },
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
            builder: (context, state) =>
                BudgetScreen(queryParams: state.uri.queryParameters),
          ),
          GoRoute(
            path: "/settings",
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: "/month-summary",
        builder: (context, state) => const MonthSummaryScreen(),
        routes: [
          GoRoute(
            path: "details",
            builder: (context, state) => const TransactionsScreen(),
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

String _titleFromLocation(String location, BuildContext context) {
  final loc = AppLocalizations.of(context);
  if (location.startsWith("/transactions"))
    return loc?.navTransactions ?? "Transações";
  if (location.startsWith("/budget")) return loc?.navBudgets ?? "Orçamentos";
  if (location.startsWith("/settings")) return loc?.navSettings ?? "Ajustes";
  return loc?.navDashboard ?? "Dashboard";
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

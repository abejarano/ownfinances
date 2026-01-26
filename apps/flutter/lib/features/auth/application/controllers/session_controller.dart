import "package:ownfinances/core/routing/onboarding_controller.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/features/banks/application/controllers/banks_controller.dart";
import "package:ownfinances/features/budgets/application/controllers/budget_controller.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/countries/application/controllers/countries_controller.dart";
import "package:ownfinances/features/csv_import/application/controllers/csv_import_controller.dart";
import "package:ownfinances/features/dashboard/application/controllers/dashboard_controller.dart";
import "package:ownfinances/features/debts/application/controllers/debts_controller.dart";
import "package:ownfinances/features/goals/application/controllers/goals_controller.dart";
import "package:ownfinances/features/month_summary/application/controllers/month_summary_controller.dart";
import "package:ownfinances/features/recurring/application/controllers/recurring_controller.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/settings/application/controllers/settings_controller.dart";
import "package:ownfinances/features/templates/application/controllers/templates_controller.dart";
import "package:ownfinances/features/transactions/application/controllers/pending_transactions_controller.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";

class SessionController {
  final AuthController authController;
  final SettingsController settingsController;
  final OnboardingController onboardingController;
  final CategoriesController categoriesController;
  final AccountsController accountsController;
  final TransactionsController transactionsController;
  final PendingTransactionsController pendingTransactionsController;
  final ReportsController reportsController;
  final DashboardController dashboardController;
  final BudgetController budgetController;
  final RecurringController recurringController;
  final TemplatesController templatesController;
  final DebtsController debtsController;
  final GoalsController goalsController;
  final CsvImportController csvImportController;
  final MonthSummaryController monthSummaryController;
  final BanksController banksController;
  final CountriesController countriesController;

  SessionController({
    required this.authController,
    required this.settingsController,
    required this.onboardingController,
    required this.categoriesController,
    required this.accountsController,
    required this.transactionsController,
    required this.pendingTransactionsController,
    required this.reportsController,
    required this.dashboardController,
    required this.budgetController,
    required this.recurringController,
    required this.templatesController,
    required this.debtsController,
    required this.goalsController,
    required this.csvImportController,
    required this.monthSummaryController,
    required this.banksController,
    required this.countriesController,
  });

  Future<void> logout() async {
    await authController.logout();
    await resetAll();
  }

  Future<void> resetAll() async {
    dashboardController.pauseSettingsListener();
    categoriesController.reset();
    accountsController.reset();
    transactionsController.reset();
    pendingTransactionsController.reset();
    reportsController.reset();
    dashboardController.reset();
    budgetController.reset();
    recurringController.reset();
    templatesController.reset();
    debtsController.reset();
    goalsController.reset();
    csvImportController.reset();
    monthSummaryController.reset();
    banksController.reset();
    countriesController.reset();
    await onboardingController.reset();
    await settingsController.reset();
    await authController.clearMessage();
    dashboardController.resumeSettingsListener();
  }
}

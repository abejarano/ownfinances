import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/recurring/data/datasources/recurring_remote_data_source.dart";
import "package:ownfinances/features/recurring/data/repositories/recurring_repository.dart";
import "package:ownfinances/features/recurring/application/controllers/recurring_controller.dart";
import "package:ownfinances/features/auth/data/datasources/auth_remote_data_source.dart";
import "package:ownfinances/features/auth/data/datasources/token_storage.dart";
import "package:ownfinances/features/auth/data/repositories/auth_repository.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/features/categories/data/datasources/category_remote_data_source.dart";
import "package:ownfinances/features/categories/data/repositories/category_repository.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/accounts/data/datasources/account_remote_data_source.dart";
import "package:ownfinances/features/accounts/data/repositories/account_repository.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/transactions/data/datasources/transaction_remote_data_source.dart";
import "package:ownfinances/features/transactions/data/repositories/transaction_repository.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/transactions/application/controllers/pending_transactions_controller.dart";
import "package:ownfinances/features/reports/data/datasources/reports_remote_data_source.dart";
import "package:ownfinances/features/reports/data/repositories/reports_repository.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/dashboard/application/controllers/dashboard_controller.dart";
import "package:ownfinances/features/budgets/data/datasources/budget_remote_data_source.dart";
import "package:ownfinances/features/budgets/data/repositories/budget_repository.dart";
import "package:ownfinances/features/budgets/application/controllers/budget_controller.dart";
import "package:ownfinances/core/routing/onboarding_controller.dart";
import "package:ownfinances/core/routing/app_router.dart";
import "package:ownfinances/core/storage/onboarding_storage.dart";

import "package:ownfinances/features/templates/data/datasources/template_remote_data_source.dart";
import "package:ownfinances/features/templates/data/repositories/template_repository.dart";
import "package:ownfinances/features/templates/application/controllers/templates_controller.dart";
import "package:ownfinances/features/debts/data/datasources/debt_remote_data_source.dart";
import "package:ownfinances/features/debts/data/datasources/debt_transaction_remote_data_source.dart";
import "package:ownfinances/features/debts/data/repositories/debt_repository.dart";
import "package:ownfinances/features/debts/data/repositories/debt_transaction_repository.dart";
import "package:ownfinances/features/debts/application/controllers/debts_controller.dart";
import "package:ownfinances/features/goals/data/datasources/goal_remote_data_source.dart";
import "package:ownfinances/features/goals/data/repositories/goal_repository.dart";
import "package:ownfinances/features/goals/application/controllers/goals_controller.dart";
import "package:ownfinances/features/csv_import/data/datasources/csv_import_remote_data_source.dart";
import "package:ownfinances/features/csv_import/data/repositories/csv_import_repository.dart";
import "package:ownfinances/features/csv_import/application/controllers/csv_import_controller.dart";
import "package:ownfinances/core/infrastructure/websocket/websocket_client.dart";
import "package:ownfinances/core/storage/settings_storage.dart";
import "package:ownfinances/features/settings/application/controllers/settings_controller.dart";
import "package:ownfinances/features/settings/data/datasources/settings_remote_data_source.dart";
import "package:ownfinances/features/settings/data/repositories/settings_repository.dart";
import "package:ownfinances/features/month_summary/application/controllers/month_summary_controller.dart";
import "package:ownfinances/features/banks/data/datasources/bank_remote_data_source.dart";
import "package:ownfinances/features/banks/data/repositories/bank_repository.dart";
import "package:ownfinances/features/banks/application/controllers/banks_controller.dart";
import "package:ownfinances/features/countries/data/datasources/country_remote_data_source.dart";
import "package:ownfinances/features/countries/data/repositories/country_repository.dart";
import "package:ownfinances/features/countries/application/controllers/countries_controller.dart";
import "package:ownfinances/features/auth/application/controllers/session_controller.dart";

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenStorage>(create: (_) => TokenStorage(onChanged: (_) {})),
        Provider<OnboardingStorage>(create: (_) => OnboardingStorage()),

        // Settings (Must be early)
        Provider<SettingsStorage>(create: (_) => SettingsStorage()),
        Provider<ApiClient>(
          create: (context) => ApiClient(
            baseUrl: kReleaseMode
                ? "https://desquadra.jaspesoft.com"
                : "http://localhost:3000",
            storage: context.read<TokenStorage>(),
          ),
        ),
        Provider<SettingsRepository>(
          create: (context) => SettingsRepository(
            SettingsRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<SettingsController>(
          create: (context) => SettingsController(
            context.read<SettingsStorage>(),
            context.read<SettingsRepository>(),
          )..load(),
        ),
        Provider<WebSocketClient>(
          create: (context) => WebSocketClient(
            baseUrl: kReleaseMode
                ? "https://desquadra.jaspesoft.com"
                : "http://localhost:3000",
            tokenStorage: context.read<TokenStorage>(),
          ),
        ),
        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            remote: AuthRemoteDataSource(context.read<ApiClient>()),
            storage: context.read<TokenStorage>(),
          ),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) {
            final controller = AuthController(
              context.read<AuthRepository>(),
              settingsController: context.read<SettingsController>(),
            );
            controller.restoreSession();
            return controller;
          },
        ),
        Provider<CategoryRepository>(
          create: (context) => CategoryRepository(
            CategoryRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<CategoriesController>(
          create: (context) =>
              CategoriesController(context.read<CategoryRepository>())..load(),
        ),
        Provider<AccountRepository>(
          create: (context) => AccountRepository(
            AccountRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<AccountsController>(
          create: (context) =>
              AccountsController(context.read<AccountRepository>())..load(),
        ),
        Provider<TransactionRepository>(
          create: (context) => TransactionRepository(
            TransactionRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<TransactionsController>(
          create: (context) =>
              TransactionsController(context.read<TransactionRepository>())
                ..load(),
        ),
        ChangeNotifierProvider<PendingTransactionsController>(
          create: (context) => PendingTransactionsController(
            context.read<TransactionRepository>(),
          ),
        ),
        Provider<DebtRepository>(
          create: (context) =>
              DebtRepository(DebtRemoteDataSource(context.read<ApiClient>())),
        ),
        Provider<DebtTransactionRepository>(
          create: (context) => DebtTransactionRepository(
            DebtTransactionRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        Provider<ReportsRepository>(
          create: (context) => ReportsRepository(
            ReportsRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<ReportsController>(
          create: (context) =>
              ReportsController(context.read<ReportsRepository>())..load(),
        ),
        ChangeNotifierProvider<DashboardController>(
          create: (context) => DashboardController(
            context.read<TransactionRepository>(),
            context.read<AccountRepository>(),
            context.read<ReportsRepository>(),
            context.read<DebtRepository>(),
            context.read<SettingsController>(),
          )..load(),
        ),
        Provider<BudgetRepository>(
          create: (context) => BudgetRepository(
            BudgetRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<BudgetController>(
          create: (context) =>
              BudgetController(context.read<BudgetRepository>()),
        ),
        Provider<RecurringRepository>(
          create: (context) => RecurringRepository(
            RecurringRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<RecurringController>(
          create: (context) =>
              RecurringController(context.read<RecurringRepository>())..load(),
        ),
        Provider<TemplateRepository>(
          create: (context) => TemplateRepository(
            TemplateRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<TemplatesController>(
          create: (context) =>
              TemplatesController(context.read<TemplateRepository>())..load(),
        ),

        ChangeNotifierProvider<DebtsController>(
          create: (context) => DebtsController(
            context.read<DebtRepository>(),
            context.read<DebtTransactionRepository>(),
          )..load(),
        ),
        Provider<GoalRepository>(
          create: (context) =>
              GoalRepository(GoalRemoteDataSource(context.read<ApiClient>())),
        ),
        ChangeNotifierProvider<GoalsController>(
          create: (context) =>
              GoalsController(context.read<GoalRepository>())..load(),
        ),
        Provider<CsvImportRepository>(
          create: (context) => CsvImportRepository(
            CsvImportRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<CsvImportController>(
          create: (context) =>
              CsvImportController(context.read<CsvImportRepository>()),
        ),
        ChangeNotifierProvider<MonthSummaryController>(
          create: (context) => MonthSummaryController(
            transactionsRepository: context.read<TransactionRepository>(),
            accountRepository: context.read<AccountRepository>(),
            categoriesRepository: context.read<CategoryRepository>(),
            settingsController: context.read<SettingsController>(),
          ),
        ),

        Provider<BankRepository>(
          create: (context) =>
              BankRepository(BankRemoteDataSource(context.read<ApiClient>())),
        ),
        ChangeNotifierProvider<BanksController>(
          create: (context) => BanksController(context.read<BankRepository>()),
        ),
        Provider<CountryRepository>(
          create: (context) => CountryRepository(
            CountryRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<CountriesController>(
          create: (context) =>
              CountriesController(context.read<CountryRepository>()),
        ),

        ChangeNotifierProvider<OnboardingController>(
          create: (context) {
            final controller = OnboardingController(
              context.read<OnboardingStorage>(),
              context.read<AccountRepository>(),
              context.read<CategoryRepository>(),
            );
            controller.load();
            return controller;
          },
        ),
        Provider<GoRouter>(
          create: (context) {
            return createRouter(
              authController: context.read<AuthController>(),
              onboardingController: context.read<OnboardingController>(),
            );
          },
        ),
        Provider<SessionController>(
          create: (context) => SessionController(
            authController: context.read<AuthController>(),
            settingsController: context.read<SettingsController>(),
            onboardingController: context.read<OnboardingController>(),
            categoriesController: context.read<CategoriesController>(),
            accountsController: context.read<AccountsController>(),
            transactionsController: context.read<TransactionsController>(),
            pendingTransactionsController: context
                .read<PendingTransactionsController>(),
            reportsController: context.read<ReportsController>(),
            dashboardController: context.read<DashboardController>(),
            budgetController: context.read<BudgetController>(),
            recurringController: context.read<RecurringController>(),
            templatesController: context.read<TemplatesController>(),
            debtsController: context.read<DebtsController>(),
            goalsController: context.read<GoalsController>(),
            csvImportController: context.read<CsvImportController>(),
            monthSummaryController: context.read<MonthSummaryController>(),
            banksController: context.read<BanksController>(),
            countriesController: context.read<CountriesController>(),
          ),
        ),
      ],
      child: child,
    );
  }
}

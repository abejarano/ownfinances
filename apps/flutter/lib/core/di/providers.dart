import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/recurring/data/datasources/recurring_remote_data_source.dart";
import "package:ownfinances/features/recurring/data/repositories/recurring_repository_impl.dart";
import "package:ownfinances/features/recurring/domain/repositories/recurring_repository.dart";
import "package:ownfinances/features/recurring/application/controllers/recurring_controller.dart";
import "package:ownfinances/features/auth/data/datasources/auth_remote_data_source.dart";
import "package:ownfinances/features/auth/data/datasources/token_storage.dart";
import "package:ownfinances/features/auth/data/repositories/auth_repository_impl.dart";
import "package:ownfinances/features/auth/domain/repositories/auth_repository.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/features/categories/data/datasources/category_remote_data_source.dart";
import "package:ownfinances/features/categories/data/repositories/category_repository_impl.dart";
import "package:ownfinances/features/categories/domain/repositories/category_repository.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/accounts/data/datasources/account_remote_data_source.dart";
import "package:ownfinances/features/accounts/data/repositories/account_repository_impl.dart";
import "package:ownfinances/features/accounts/domain/repositories/account_repository.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/transactions/data/datasources/transaction_remote_data_source.dart";
import "package:ownfinances/features/transactions/data/repositories/transaction_repository_impl.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/transactions/application/controllers/pending_transactions_controller.dart";
import "package:ownfinances/features/reports/data/datasources/reports_remote_data_source.dart";
import "package:ownfinances/features/reports/data/repositories/reports_repository_impl.dart";
import "package:ownfinances/features/reports/domain/repositories/reports_repository.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/budgets/data/datasources/budget_remote_data_source.dart";
import "package:ownfinances/features/budgets/data/repositories/budget_repository_impl.dart";
import "package:ownfinances/features/budgets/domain/repositories/budget_repository.dart";
import "package:ownfinances/features/budgets/application/controllers/budget_controller.dart";
import "package:ownfinances/core/routing/onboarding_controller.dart";
import "package:ownfinances/core/routing/app_router.dart";
import "package:ownfinances/core/storage/onboarding_storage.dart";

import "package:ownfinances/features/templates/data/datasources/template_remote_data_source.dart";
import "package:ownfinances/features/templates/data/repositories/template_repository_impl.dart";
import "package:ownfinances/features/templates/domain/repositories/template_repository.dart";
import "package:ownfinances/features/templates/application/controllers/templates_controller.dart";
import "package:ownfinances/features/debts/data/datasources/debt_remote_data_source.dart";
import "package:ownfinances/features/debts/data/datasources/debt_transaction_remote_data_source.dart";
import "package:ownfinances/features/debts/data/repositories/debt_repository_impl.dart";
import "package:ownfinances/features/debts/data/repositories/debt_transaction_repository_impl.dart";
import "package:ownfinances/features/debts/domain/repositories/debt_repository.dart";
import "package:ownfinances/features/debts/domain/repositories/debt_transaction_repository.dart";
import "package:ownfinances/features/debts/application/controllers/debts_controller.dart";
import "package:ownfinances/features/goals/data/datasources/goal_remote_data_source.dart";
import "package:ownfinances/features/goals/data/repositories/goal_repository_impl.dart";
import "package:ownfinances/features/goals/domain/repositories/goal_repository.dart";
import "package:ownfinances/features/goals/application/controllers/goals_controller.dart";
import "package:ownfinances/features/csv_import/data/datasources/csv_import_remote_data_source.dart";
import "package:ownfinances/features/csv_import/data/repositories/csv_import_repository_impl.dart";
import "package:ownfinances/features/csv_import/domain/repositories/csv_import_repository.dart";
import "package:ownfinances/features/csv_import/application/controllers/csv_import_controller.dart";
import "package:ownfinances/core/infrastructure/websocket/websocket_client.dart";

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenStorage>(create: (_) => TokenStorage(onChanged: (_) {})),
        Provider<OnboardingStorage>(create: (_) => OnboardingStorage()),
        Provider<ApiClient>(
          create: (context) => ApiClient(
            baseUrl: "http://localhost:3000",
            storage: context.read<TokenStorage>(),
          ),
        ),
        // Provider<WebSocketClient>(
        //   create: (context) => WebSocketClient(
        //     baseUrl: "http://localhost:3000",
        //     tokenStorage: context.read<TokenStorage>(),
        //   ),
        // ),
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            remote: AuthRemoteDataSource(context.read<ApiClient>()),
            storage: context.read<TokenStorage>(),
          ),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) {
            final controller = AuthController(context.read<AuthRepository>());
            controller.restoreSession();
            return controller;
          },
        ),
        Provider<CategoryRepository>(
          create: (context) => CategoryRepositoryImpl(
            CategoryRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<CategoriesController>(
          create: (context) =>
              CategoriesController(context.read<CategoryRepository>())..load(),
        ),
        Provider<AccountRepository>(
          create: (context) => AccountRepositoryImpl(
            AccountRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<AccountsController>(
          create: (context) =>
              AccountsController(context.read<AccountRepository>())..load(),
        ),
        Provider<TransactionRepository>(
          create: (context) => TransactionRepositoryImpl(
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
        Provider<ReportsRepository>(
          create: (context) => ReportsRepositoryImpl(
            ReportsRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<ReportsController>(
          create: (context) =>
              ReportsController(context.read<ReportsRepository>())..load(),
        ),
        Provider<BudgetRepository>(
          create: (context) => BudgetRepositoryImpl(
            BudgetRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<BudgetController>(
          create: (context) =>
              BudgetController(context.read<BudgetRepository>()),
        ),
        Provider<RecurringRepository>(
          create: (context) => RecurringRepositoryImpl(
            RecurringRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<RecurringController>(
          create: (context) =>
              RecurringController(context.read<RecurringRepository>())..load(),
        ),
        Provider<TemplateRepository>(
          create: (context) => TemplateRepositoryImpl(
            TemplateRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<TemplatesController>(
          create: (context) =>
              TemplatesController(context.read<TemplateRepository>())..load(),
        ),
        Provider<DebtRepository>(
          create: (context) => DebtRepositoryImpl(
            DebtRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        Provider<DebtTransactionRepository>(
          create: (context) => DebtTransactionRepositoryImpl(
            DebtTransactionRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<DebtsController>(
          create: (context) => DebtsController(
            context.read<DebtRepository>(),
            context.read<DebtTransactionRepository>(),
          )..load(),
        ),
        Provider<GoalRepository>(
          create: (context) => GoalRepositoryImpl(
            GoalRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<GoalsController>(
          create: (context) =>
              GoalsController(context.read<GoalRepository>())..load(),
        ),
        Provider<CsvImportRepository>(
          create: (context) => CsvImportRepositoryImpl(
            CsvImportRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<CsvImportController>(
          create: (context) => CsvImportController(
            context.read<CsvImportRepository>(),
            webSocketClient: context.read<WebSocketClient>(),
          ),
        ),

        ChangeNotifierProvider<OnboardingController>(
          create: (context) {
            final controller = OnboardingController(
              context.read<OnboardingStorage>(),
              context.read<AccountRepository>(),
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
      ],
      child: child,
    );
  }
}

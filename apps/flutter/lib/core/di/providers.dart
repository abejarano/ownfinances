import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:go_router/go_router.dart";
import "package:ownfinances/core/infrastructure/api/api_client.dart";
import "package:ownfinances/features/recurring/data/datasources/recurring_remote_data_source.dart";
import "package:ownfinances/features/recurring/data/repositories/recurring_repository_impl.dart";
import "package:ownfinances/features/recurring/domain/repositories/recurring_repository.dart";
import "package:ownfinances/features/recurring/domain/use_cases/create_recurring_rule_use_case.dart";
import "package:ownfinances/features/recurring/domain/use_cases/delete_recurring_rule_use_case.dart";
import "package:ownfinances/features/recurring/domain/use_cases/list_recurring_rules_use_case.dart";
import "package:ownfinances/features/recurring/domain/use_cases/preview_recurring_rules_use_case.dart";
import "package:ownfinances/features/recurring/domain/use_cases/run_recurring_rules_use_case.dart";
import "package:ownfinances/features/recurring/domain/use_cases/split_recurring_rule_use_case.dart";
import "package:ownfinances/features/recurring/domain/use_cases/materialize_recurring_instance_use_case.dart";
import "package:ownfinances/features/recurring/application/controllers/recurring_controller.dart";
import "package:ownfinances/features/auth/data/datasources/auth_remote_data_source.dart";
import "package:ownfinances/features/auth/data/datasources/token_storage.dart";
import "package:ownfinances/features/auth/data/repositories/auth_repository_impl.dart";
import "package:ownfinances/features/auth/domain/repositories/auth_repository.dart";
import "package:ownfinances/features/auth/domain/use_cases/login_use_case.dart";
import "package:ownfinances/features/auth/domain/use_cases/logout_use_case.dart";
import "package:ownfinances/features/auth/domain/use_cases/register_use_case.dart";
import "package:ownfinances/features/auth/domain/use_cases/restore_session_use_case.dart";
import "package:ownfinances/features/auth/application/controllers/auth_controller.dart";
import "package:ownfinances/features/categories/data/datasources/category_remote_data_source.dart";
import "package:ownfinances/features/categories/data/repositories/category_repository_impl.dart";
import "package:ownfinances/features/categories/domain/repositories/category_repository.dart";
import "package:ownfinances/features/categories/domain/use_cases/create_category_use_case.dart";
import "package:ownfinances/features/categories/domain/use_cases/delete_category_use_case.dart";
import "package:ownfinances/features/categories/domain/use_cases/list_categories_use_case.dart";
import "package:ownfinances/features/categories/domain/use_cases/update_category_use_case.dart";
import "package:ownfinances/features/categories/application/controllers/categories_controller.dart";
import "package:ownfinances/features/accounts/data/datasources/account_remote_data_source.dart";
import "package:ownfinances/features/accounts/data/repositories/account_repository_impl.dart";
import "package:ownfinances/features/accounts/domain/repositories/account_repository.dart";
import "package:ownfinances/features/accounts/domain/use_cases/create_account_use_case.dart";
import "package:ownfinances/features/accounts/domain/use_cases/delete_account_use_case.dart";
import "package:ownfinances/features/accounts/domain/use_cases/list_accounts_use_case.dart";
import "package:ownfinances/features/accounts/domain/use_cases/update_account_use_case.dart";
import "package:ownfinances/features/accounts/application/controllers/accounts_controller.dart";
import "package:ownfinances/features/transactions/data/datasources/transaction_remote_data_source.dart";
import "package:ownfinances/features/transactions/data/repositories/transaction_repository_impl.dart";
import "package:ownfinances/features/transactions/domain/repositories/transaction_repository.dart";
import "package:ownfinances/features/transactions/domain/use_cases/clear_transaction_use_case.dart";
import "package:ownfinances/features/transactions/domain/use_cases/create_transaction_use_case.dart";
import "package:ownfinances/features/transactions/domain/use_cases/delete_transaction_use_case.dart";
import "package:ownfinances/features/transactions/domain/use_cases/list_transactions_use_case.dart";
import "package:ownfinances/features/transactions/domain/use_cases/update_transaction_use_case.dart";
import "package:ownfinances/features/transactions/application/controllers/transactions_controller.dart";
import "package:ownfinances/features/reports/data/datasources/reports_remote_data_source.dart";
import "package:ownfinances/features/reports/data/repositories/reports_repository_impl.dart";
import "package:ownfinances/features/reports/domain/repositories/reports_repository.dart";
import "package:ownfinances/features/reports/domain/use_cases/get_summary_use_case.dart";
import "package:ownfinances/features/reports/application/controllers/reports_controller.dart";
import "package:ownfinances/features/budgets/data/datasources/budget_remote_data_source.dart";
import "package:ownfinances/features/budgets/data/repositories/budget_repository_impl.dart";
import "package:ownfinances/features/budgets/domain/repositories/budget_repository.dart";
import "package:ownfinances/features/budgets/domain/use_cases/get_current_budget_use_case.dart";
import "package:ownfinances/features/budgets/domain/use_cases/save_budget_use_case.dart";
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
import "package:ownfinances/features/debts/domain/use_cases/list_debts_use_case.dart";
import "package:ownfinances/features/debts/domain/use_cases/create_debt_use_case.dart";
import "package:ownfinances/features/debts/domain/use_cases/update_debt_use_case.dart";
import "package:ownfinances/features/debts/domain/use_cases/delete_debt_use_case.dart";
import "package:ownfinances/features/debts/domain/use_cases/get_debt_summary_use_case.dart";
import "package:ownfinances/features/debts/domain/use_cases/create_debt_transaction_use_case.dart";
import "package:ownfinances/features/debts/application/controllers/debts_controller.dart";
import "package:ownfinances/features/goals/data/datasources/goal_remote_data_source.dart";
import "package:ownfinances/features/goals/data/repositories/goal_repository_impl.dart";
import "package:ownfinances/features/goals/domain/repositories/goal_repository.dart";
import "package:ownfinances/features/goals/domain/use_cases/list_goals_use_case.dart";
import "package:ownfinances/features/goals/domain/use_cases/create_goal_use_case.dart";
import "package:ownfinances/features/goals/domain/use_cases/update_goal_use_case.dart";
import "package:ownfinances/features/goals/domain/use_cases/delete_goal_use_case.dart";
import "package:ownfinances/features/goals/domain/use_cases/get_goal_projection_use_case.dart";
import "package:ownfinances/features/goals/domain/use_cases/create_goal_contribution_use_case.dart";
import "package:ownfinances/features/goals/application/controllers/goals_controller.dart";

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
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            remote: AuthRemoteDataSource(context.read<ApiClient>()),
            storage: context.read<TokenStorage>(),
          ),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) {
            final repo = context.read<AuthRepository>();
            final controller = AuthController(
              LoginUseCase(repo),
              RegisterUseCase(repo),
              LogoutUseCase(repo),
              RestoreSessionUseCase(repo),
              repo,
            );
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
          create: (context) => CategoriesController(
            ListCategoriesUseCase(context.read<CategoryRepository>()),
            CreateCategoryUseCase(context.read<CategoryRepository>()),
            UpdateCategoryUseCase(context.read<CategoryRepository>()),
            DeleteCategoryUseCase(context.read<CategoryRepository>()),
          )..load(),
        ),
        Provider<AccountRepository>(
          create: (context) => AccountRepositoryImpl(
            AccountRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<AccountsController>(
          create: (context) => AccountsController(
            ListAccountsUseCase(context.read<AccountRepository>()),
            CreateAccountUseCase(context.read<AccountRepository>()),
            UpdateAccountUseCase(context.read<AccountRepository>()),
            DeleteAccountUseCase(context.read<AccountRepository>()),
          )..load(),
        ),
        Provider<TransactionRepository>(
          create: (context) => TransactionRepositoryImpl(
            TransactionRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<TransactionsController>(
          create: (context) => TransactionsController(
            ListTransactionsUseCase(context.read<TransactionRepository>()),
            CreateTransactionUseCase(context.read<TransactionRepository>()),
            UpdateTransactionUseCase(context.read<TransactionRepository>()),
            DeleteTransactionUseCase(context.read<TransactionRepository>()),
            ClearTransactionUseCase(context.read<TransactionRepository>()),
          )..load(),
        ),
        Provider<ReportsRepository>(
          create: (context) => ReportsRepositoryImpl(
            ReportsRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<ReportsController>(
          create: (context) => ReportsController(
            GetSummaryUseCase(context.read<ReportsRepository>()),
          )..load(),
        ),
        Provider<BudgetRepository>(
          create: (context) => BudgetRepositoryImpl(
            BudgetRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<BudgetController>(
          create: (context) => BudgetController(
            GetCurrentBudgetUseCase(context.read<BudgetRepository>()),
            SaveBudgetUseCase(context.read<BudgetRepository>()),
          ),
        ),
        Provider<RecurringRepository>(
          create: (context) => RecurringRepositoryImpl(
            RecurringRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<RecurringController>(
          create: (context) => RecurringController(
            ListRecurringRulesUseCase(context.read<RecurringRepository>()),
            CreateRecurringRuleUseCase(context.read<RecurringRepository>()),
            DeleteRecurringRuleUseCase(context.read<RecurringRepository>()),
            PreviewRecurringRulesUseCase(context.read<RecurringRepository>()),
            RunRecurringRulesUseCase(context.read<RecurringRepository>()),
            SplitRecurringRuleUseCase(context.read<RecurringRepository>()),
            MaterializeRecurringInstanceUseCase(
              context.read<RecurringRepository>(),
            ),
          )..load(),
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
          create: (context) =>
              DebtRepositoryImpl(DebtRemoteDataSource(context.read<ApiClient>())),
        ),
        Provider<DebtTransactionRepository>(
          create: (context) => DebtTransactionRepositoryImpl(
            DebtTransactionRemoteDataSource(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<DebtsController>(
          create: (context) => DebtsController(
            ListDebtsUseCase(context.read<DebtRepository>()),
            CreateDebtUseCase(context.read<DebtRepository>()),
            UpdateDebtUseCase(context.read<DebtRepository>()),
            DeleteDebtUseCase(context.read<DebtRepository>()),
            GetDebtSummaryUseCase(context.read<DebtRepository>()),
            CreateDebtTransactionUseCase(
              context.read<DebtTransactionRepository>(),
            ),
          )..load(),
        ),
        Provider<GoalRepository>(
          create: (context) =>
              GoalRepositoryImpl(GoalRemoteDataSource(context.read<ApiClient>())),
        ),
        ChangeNotifierProvider<GoalsController>(
          create: (context) => GoalsController(
            ListGoalsUseCase(context.read<GoalRepository>()),
            CreateGoalUseCase(context.read<GoalRepository>()),
            UpdateGoalUseCase(context.read<GoalRepository>()),
            DeleteGoalUseCase(context.read<GoalRepository>()),
            GetGoalProjectionUseCase(context.read<GoalRepository>()),
            CreateGoalContributionUseCase(context.read<GoalRepository>()),
          )..load(),
        ),
        ChangeNotifierProvider<OnboardingController>(
          create: (context) {
            final controller = OnboardingController(
              context.read<OnboardingStorage>(),
            );
            controller.load();
            return controller;
          },
        ),
        ProxyProvider2<AuthController, OnboardingController, GoRouter>(
          update: (context, auth, onboarding, previous) {
            return createRouter(
              authController: auth,
              onboardingController: onboarding,
            );
          },
        ),
      ],
      child: child,
    );
  }
}

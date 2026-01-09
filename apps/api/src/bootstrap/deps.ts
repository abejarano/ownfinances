import { CategoryMongoRepository } from "../repositories/category_repository";
import { AccountMongoRepository } from "../repositories/account_repository";
import { TransactionMongoRepository } from "../repositories/transaction_repository";
import { TransactionsService } from "../services/transactions_service";
import { CategoriesService } from "../services/categories_service";
import { AccountsService } from "../services/accounts_service";
import { UserMongoRepository } from "../repositories/user_mongo_repository";
import { RefreshTokenMongoRepository } from "../repositories/refresh_token_mongo_repository";
import { AuthService } from "../services/auth_service";
import { BudgetMongoRepository } from "../repositories/budget_repository";
import { BudgetsService } from "../services/budgets_service";
import { ReportsService } from "../services/reports_service";
import { RecurringRuleMongoRepository } from "../repositories/recurring_rule_repository";
import { GeneratedInstanceMongoRepository } from "../repositories/generated_instance_repository";
import { RecurringService } from "../services/recurring_service";
import { TransactionTemplateMongoRepository } from "../repositories/transaction_template_repository";
import { TemplateService } from "../services/template_service";
import { DebtMongoRepository } from "../repositories/debt_repository";
import { DebtTransactionMongoRepository } from "../repositories/debt_transaction_repository";
import { DebtsService } from "../services/debts_service";
import { DebtTransactionsService } from "../services/debt_transactions_service";
import { GoalMongoRepository } from "../repositories/goal_repository";
import { GoalContributionMongoRepository } from "../repositories/goal_contribution_repository";
import { GoalsService } from "../services/goals_service";
import { GoalContributionsService } from "../services/goal_contributions_service";

export type AppDeps = {
  readonly categoryRepo: CategoryMongoRepository;
  readonly accountRepo: AccountMongoRepository;
  readonly transactionRepo: TransactionMongoRepository;
  readonly transactionsService: TransactionsService;
  readonly categoriesService: CategoriesService;
  readonly accountsService: AccountsService;
  readonly userRepo: UserMongoRepository;
  readonly refreshTokenRepo: RefreshTokenMongoRepository;
  readonly authService: AuthService;
  readonly budgetRepo: BudgetMongoRepository;
  readonly budgetsService: BudgetsService;
  readonly reportsService: ReportsService;
  readonly recurringRuleRepo: RecurringRuleMongoRepository;
  readonly generatedInstanceRepo: GeneratedInstanceMongoRepository;
  readonly recurringService: RecurringService;
  readonly templateRepo: TransactionTemplateMongoRepository;
  readonly templateService: TemplateService;
  readonly debtRepo: DebtMongoRepository;
  readonly debtTransactionRepo: DebtTransactionMongoRepository;
  readonly debtsService: DebtsService;
  readonly debtTransactionsService: DebtTransactionsService;
  readonly goalRepo: GoalMongoRepository;
  readonly goalContributionRepo: GoalContributionMongoRepository;
  readonly goalsService: GoalsService;
  readonly goalContributionsService: GoalContributionsService;
};

export function buildDeps(): AppDeps {
  let transactionsService: TransactionsService | null = null;
  let categoriesService: CategoriesService | null = null;
  let accountsService: AccountsService | null = null;
  let authService: AuthService | null = null;
  let budgetsService: BudgetsService | null = null;
  let reportsService: ReportsService | null = null;
  let recurringService: RecurringService | null = null;
  let templateService: TemplateService | null = null;
  let debtsService: DebtsService | null = null;
  let debtTransactionsService: DebtTransactionsService | null = null;
  let goalsService: GoalsService | null = null;
  let goalContributionsService: GoalContributionsService | null = null;

  return {
    get categoryRepo() {
      return CategoryMongoRepository.getInstance();
    },
    get accountRepo() {
      return AccountMongoRepository.getInstance();
    },
    get transactionRepo() {
      return TransactionMongoRepository.getInstance();
    },
    get transactionsService() {
      if (!transactionsService) {
        transactionsService = new TransactionsService(
          this.transactionRepo,
          this.accountRepo
        );
      }
      return transactionsService;
    },
    get categoriesService() {
      if (!categoriesService) {
        categoriesService = new CategoriesService(
          this.categoryRepo,
          this.transactionRepo
        );
      }
      return categoriesService;
    },
    get accountsService() {
      if (!accountsService) {
        accountsService = new AccountsService(this.accountRepo, this.transactionRepo);
      }
      return accountsService;
    },
    get userRepo() {
      return UserMongoRepository.getInstance();
    },
    get refreshTokenRepo() {
      return RefreshTokenMongoRepository.getInstance();
    },
    get authService() {
      if (!authService) {
        authService = new AuthService(this.userRepo, this.refreshTokenRepo);
      }
      return authService;
    },
    get budgetRepo() {
      return BudgetMongoRepository.getInstance();
    },
    get budgetsService() {
      if (!budgetsService) {
        budgetsService = new BudgetsService(this.budgetRepo);
      }
      return budgetsService;
    },
    get reportsService() {
      if (!reportsService) {
        reportsService = new ReportsService(
          this.budgetRepo,
          this.categoryRepo,
          this.transactionRepo
        );
      }
      return reportsService;
    },
    get recurringRuleRepo() {
      return RecurringRuleMongoRepository.getInstance();
    },
    get generatedInstanceRepo() {
      return GeneratedInstanceMongoRepository.getInstance();
    },
    get recurringService() {
      if (!recurringService) {
        recurringService = new RecurringService(
          this.recurringRuleRepo,
          this.generatedInstanceRepo,
          this.transactionRepo
        );
      }
      return recurringService;
    },
    get templateRepo() {
      return TransactionTemplateMongoRepository.getInstance();
    },
    get templateService() {
      if (!templateService) {
        templateService = new TemplateService(this.templateRepo);
      }
      return templateService;
    },
    get debtRepo() {
      return DebtMongoRepository.getInstance();
    },
    get debtTransactionRepo() {
      return DebtTransactionMongoRepository.getInstance();
    },
    get debtsService() {
      if (!debtsService) {
        debtsService = new DebtsService(
          this.debtRepo,
          this.debtTransactionRepo
        );
      }
      return debtsService;
    },
    get debtTransactionsService() {
      if (!debtTransactionsService) {
        debtTransactionsService = new DebtTransactionsService(
          this.debtTransactionRepo,
          this.debtRepo,
          this.accountRepo,
          this.transactionRepo,
          this.categoryRepo
        );
      }
      return debtTransactionsService;
    },
    get goalRepo() {
      return GoalMongoRepository.getInstance();
    },
    get goalContributionRepo() {
      return GoalContributionMongoRepository.getInstance();
    },
    get goalsService() {
      if (!goalsService) {
        goalsService = new GoalsService(
          this.goalRepo,
          this.goalContributionRepo,
          this.transactionRepo
        );
      }
      return goalsService;
    },
    get goalContributionsService() {
      if (!goalContributionsService) {
        goalContributionsService = new GoalContributionsService(
          this.goalContributionRepo,
          this.goalRepo,
          this.accountRepo,
          this.transactionRepo
        );
      }
      return goalContributionsService;
    },
  };
}

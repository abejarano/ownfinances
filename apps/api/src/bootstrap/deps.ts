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
        categoriesService = new CategoriesService(this.categoryRepo);
      }
      return categoriesService;
    },
    get accountsService() {
      if (!accountsService) {
        accountsService = new AccountsService(this.accountRepo);
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
  };
}

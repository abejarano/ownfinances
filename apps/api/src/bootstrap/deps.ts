import { CategoryMongoRepository } from "../repositories/category_repository";
import { AccountMongoRepository } from "../repositories/account_repository";
import { TransactionMongoRepository } from "../repositories/transaction_repository";
import { TransactionsService } from "../application/services/transactions_service";
import { CategoriesService } from "../application/services/categories_service";
import { AccountsService } from "../application/services/accounts_service";
import { UserMongoRepository } from "../infrastructure/repositories/user_mongo_repository";
import { RefreshTokenMongoRepository } from "../infrastructure/repositories/refresh_token_mongo_repository";
import { AuthService } from "../application/services/auth.service";
import { BudgetMongoRepository } from "../repositories/budget_repository";
import { BudgetsService } from "../application/services/budgets_service";
import { ReportsService } from "../application/services/reports_service";

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
};

export function buildDeps(): AppDeps {
  let transactionsService: TransactionsService | null = null;
  let categoriesService: CategoriesService | null = null;
  let accountsService: AccountsService | null = null;
  let authService: AuthService | null = null;
  let budgetsService: BudgetsService | null = null;
  let reportsService: ReportsService | null = null;

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
          this.accountRepo,
        );
      }
      return transactionsService;
    },
    get categoriesService() {
      if (!categoriesService) {
        categoriesService = new CategoriesService(
          this.categoryRepo,
        );
      }
      return categoriesService;
    },
    get accountsService() {
      if (!accountsService) {
        accountsService = new AccountsService(
          this.accountRepo,
        );
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
          this.transactionRepo,
        );
      }
      return reportsService;
    },
  };
}

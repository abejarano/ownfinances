import { env } from "../shared/env";
import { CategoryMongoRepository } from "../repositories/category_repository";
import { AccountMongoRepository } from "../repositories/account_repository";
import { TransactionMongoRepository } from "../repositories/transaction_repository";
import { TransactionsService } from "../application/services/transactions_service";
import { CategoriesService } from "../application/services/categories_service";
import { AccountsService } from "../application/services/accounts_service";

export type AppDeps = {
  readonly categoryRepo: CategoryMongoRepository;
  readonly accountRepo: AccountMongoRepository;
  readonly transactionRepo: TransactionMongoRepository;
  readonly transactionsService: TransactionsService;
  readonly categoriesService: CategoriesService;
  readonly accountsService: AccountsService;
};

export function buildDeps(): AppDeps {
  let transactionsService: TransactionsService | null = null;
  let categoriesService: CategoriesService | null = null;
  let accountsService: AccountsService | null = null;

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
          env.USER_ID_DEFAULT,
        );
      }
      return transactionsService;
    },
    get categoriesService() {
      if (!categoriesService) {
        categoriesService = new CategoriesService(
          this.categoryRepo,
          env.USER_ID_DEFAULT,
        );
      }
      return categoriesService;
    },
    get accountsService() {
      if (!accountsService) {
        accountsService = new AccountsService(
          this.accountRepo,
          env.USER_ID_DEFAULT,
        );
      }
      return accountsService;
    },
  };
}

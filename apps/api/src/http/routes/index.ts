import type { AppDeps } from "../../bootstrap/deps";
import { CategoriesController } from "../controllers/categories.controller";
import { AccountsController } from "../controllers/accounts.controller";
import { TransactionsController } from "../controllers/transactions.controller";

export function registerRoutes(app: any, deps: AppDeps, userId: string) {
  let categoriesController: CategoriesController | null = null;
  let accountsController: AccountsController | null = null;
  let transactionsController: TransactionsController | null = null;

  const getCategoriesController = () => {
    if (!categoriesController) {
      categoriesController = new CategoriesController(
        deps.categoryRepo,
        deps.categoriesService,
        userId,
      );
    }
    return categoriesController;
  };

  const getAccountsController = () => {
    if (!accountsController) {
      accountsController = new AccountsController(
        deps.accountRepo,
        deps.accountsService,
        userId,
      );
    }
    return accountsController;
  };

  const getTransactionsController = () => {
    if (!transactionsController) {
      transactionsController = new TransactionsController(
        deps.transactionRepo,
        deps.transactionsService,
        userId,
      );
    }
    return transactionsController;
  };

  app
    .get("/categories", (ctx: any) => getCategoriesController().list(ctx))
    .post("/categories", (ctx: any) => getCategoriesController().create(ctx))
    .get("/categories/:id", (ctx: any) => getCategoriesController().getById(ctx))
    .put("/categories/:id", (ctx: any) => getCategoriesController().update(ctx))
    .delete("/categories/:id", (ctx: any) => getCategoriesController().remove(ctx))
    .get("/accounts", (ctx: any) => getAccountsController().list(ctx))
    .post("/accounts", (ctx: any) => getAccountsController().create(ctx))
    .get("/accounts/:id", (ctx: any) => getAccountsController().getById(ctx))
    .put("/accounts/:id", (ctx: any) => getAccountsController().update(ctx))
    .delete("/accounts/:id", (ctx: any) => getAccountsController().remove(ctx))
    .get("/transactions", (ctx: any) => getTransactionsController().list(ctx))
    .post("/transactions", (ctx: any) => getTransactionsController().create(ctx))
    .get("/transactions/:id", (ctx: any) => getTransactionsController().getById(ctx))
    .put("/transactions/:id", (ctx: any) => getTransactionsController().update(ctx))
    .delete("/transactions/:id", (ctx: any) => getTransactionsController().remove(ctx))
    .post("/transactions/:id/clear", (ctx: any) => getTransactionsController().clear(ctx));
}

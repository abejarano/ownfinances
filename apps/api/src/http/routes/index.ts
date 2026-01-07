import type { AppDeps } from "../../bootstrap/deps";
import { CategoriesController } from "../controllers/categories.controller";
import { AccountsController } from "../controllers/accounts.controller";
import { TransactionsController } from "../controllers/transactions.controller";
import { BudgetsController } from "../controllers/budgets.controller";
import { ReportsController } from "../controllers/reports.controller";
import { requireAuth } from "../middleware/auth.middleware";
import { registerAuthRoutes } from "./auth.routes";
import { registerRecurringRoutes } from "./recurring.routes";

export function registerRoutes(app: any, deps: AppDeps) {
  let categoriesController: CategoriesController | null = null;
  let accountsController: AccountsController | null = null;
  let transactionsController: TransactionsController | null = null;
  let budgetsController: BudgetsController | null = null;
  let reportsController: ReportsController | null = null;

  const getCategoriesController = () => {
    if (!categoriesController) {
      categoriesController = new CategoriesController(
        deps.categoryRepo,
        deps.categoriesService,
      );
    }
    return categoriesController;
  };

  const getAccountsController = () => {
    if (!accountsController) {
      accountsController = new AccountsController(
        deps.accountRepo,
        deps.accountsService,
      );
    }
    return accountsController;
  };

  const getTransactionsController = () => {
    if (!transactionsController) {
      transactionsController = new TransactionsController(
        deps.transactionRepo,
        deps.transactionsService,
      );
    }
    return transactionsController;
  };

  const getBudgetsController = () => {
    if (!budgetsController) {
      budgetsController = new BudgetsController(
        deps.budgetRepo,
        deps.budgetsService,
      );
    }
    return budgetsController;
  };

  const getReportsController = () => {
    if (!reportsController) {
      reportsController = new ReportsController(deps.reportsService);
    }
    return reportsController;
  };

  registerAuthRoutes(app, deps);
  registerRecurringRoutes(app, deps);

  app
    .get("/categories", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getCategoriesController().list(ctx);
    })
    .post("/categories", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getCategoriesController().create(ctx);
    })
    .get("/categories/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getCategoriesController().getById(ctx);
    })
    .put("/categories/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getCategoriesController().update(ctx);
    })
    .delete("/categories/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getCategoriesController().remove(ctx);
    })
    .get("/accounts", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getAccountsController().list(ctx);
    })
    .post("/accounts", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getAccountsController().create(ctx);
    })
    .get("/accounts/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getAccountsController().getById(ctx);
    })
    .put("/accounts/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getAccountsController().update(ctx);
    })
    .delete("/accounts/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getAccountsController().remove(ctx);
    })
    .get("/transactions", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getTransactionsController().list(ctx);
    })
    .post("/transactions", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getTransactionsController().create(ctx);
    })
    .get("/transactions/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getTransactionsController().getById(ctx);
    })
    .put("/transactions/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getTransactionsController().update(ctx);
    })
    .delete("/transactions/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getTransactionsController().remove(ctx);
    })
    .post("/transactions/:id/clear", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getTransactionsController().clear(ctx);
    })
    .get("/budgets", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getBudgetsController().list(ctx);
    })
    .post("/budgets", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getBudgetsController().create(ctx);
    })
    .get("/budgets/current", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getBudgetsController().current(ctx);
    })
    .get("/budgets/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getBudgetsController().getById(ctx);
    })
    .put("/budgets/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getBudgetsController().update(ctx);
    })
    .delete("/budgets/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getBudgetsController().remove(ctx);
    })
    .get("/reports/summary", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getReportsController().summary(ctx);
    });
}

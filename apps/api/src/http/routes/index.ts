import type { AppDeps } from "../../bootstrap/deps";
import { CategoriesController } from "../controllers/categories.controller";
import { AccountsController } from "../controllers/accounts.controller";
import { TransactionsController } from "../controllers/transactions.controller";
import { BudgetsController } from "../controllers/budgets.controller";
import { ReportsController } from "../controllers/reports.controller";
import { DebtsController } from "../controllers/debts.controller";
import { DebtTransactionsController } from "../controllers/debt_transactions.controller";
import { GoalsController } from "../controllers/goals.controller";
import { requireAuth } from "../middleware/auth.middleware";
import { registerAuthRoutes } from "./auth.routes";
import { registerRecurringRoutes } from "./recurring.routes";
import { registerTemplateRoutes } from "./templates.routes";
import { badRequest } from "../errors";
import { validateAccountPayload } from "../validation/accounts.validation";
import { validateCategoryPayload } from "../validation/categories.validation";
import { validateBudgetPayload } from "../validation/budgets.validation";
import { validateTransactionPayload } from "../validation/transactions.validation";
import { validateDebtPayload } from "../validation/debts.validation";
import { validateDebtTransactionPayload } from "../validation/debt_transactions.validation";
import { validateGoalPayload } from "../validation/goals.validation";
import { validateGoalContributionPayload } from "../validation/goal_contributions.validation";

export function registerRoutes(app: any, deps: AppDeps) {
  let categoriesController: CategoriesController | null = null;
  let accountsController: AccountsController | null = null;
  let transactionsController: TransactionsController | null = null;
  let budgetsController: BudgetsController | null = null;
  let reportsController: ReportsController | null = null;
  let debtsController: DebtsController | null = null;
  let debtTransactionsController: DebtTransactionsController | null = null;
  let goalsController: GoalsController | null = null;

  const getCategoriesController = () => {
    if (!categoriesController) {
      categoriesController = new CategoriesController(
        deps.categoryRepo,
        deps.categoriesService
      );
    }
    return categoriesController;
  };

  const getAccountsController = () => {
    if (!accountsController) {
      accountsController = new AccountsController(
        deps.accountRepo,
        deps.accountsService
      );
    }
    return accountsController;
  };

  const getTransactionsController = () => {
    if (!transactionsController) {
      transactionsController = new TransactionsController(
        deps.transactionRepo,
        deps.transactionsService,
        deps.reportsService
      );
    }
    return transactionsController;
  };

  const getBudgetsController = () => {
    if (!budgetsController) {
      budgetsController = new BudgetsController(
        deps.budgetRepo,
        deps.budgetsService
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

  const getDebtsController = () => {
    if (!debtsController) {
      debtsController = new DebtsController(deps.debtRepo, deps.debtsService);
    }
    return debtsController;
  };

  const getDebtTransactionsController = () => {
    if (!debtTransactionsController) {
      debtTransactionsController = new DebtTransactionsController(
        deps.debtTransactionRepo,
        deps.debtTransactionsService
      );
    }
    return debtTransactionsController;
  };

  const getGoalsController = () => {
    if (!goalsController) {
      goalsController = new GoalsController(
        deps.goalRepo,
        deps.goalsService,
        deps.goalContributionsService,
        deps.goalContributionRepo
      );
    }
    return goalsController;
  };

  registerAuthRoutes(app, deps);
  registerRecurringRoutes(app, deps);
  registerTemplateRoutes(app, deps);

  app
    .get("/categories", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getCategoriesController().list(ctx);
    })
    .post("/categories", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateCategoryPayload(ctx.body, false);
      if (error) return badRequest(ctx.set, error);
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
      const error = validateCategoryPayload(ctx.body, true);
      if (error) return badRequest(ctx.set, error);
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
      const error = validateAccountPayload(ctx.body, false);
      if (error) return badRequest(ctx.set, error);
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
      const error = validateAccountPayload(ctx.body, true);
      if (error) return badRequest(ctx.set, error);
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
      const error = validateTransactionPayload(ctx.body, false);
      if (error) return badRequest(ctx.set, error);
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
      const error = validateTransactionPayload(ctx.body, true);
      if (error) return badRequest(ctx.set, error);
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
    .post("/transactions/:id/restore", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getTransactionsController().restore(ctx);
    })
    .get("/budgets", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getBudgetsController().list(ctx);
    })
    .post("/budgets", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateBudgetPayload(ctx.body, false);
      if (error) return badRequest(ctx.set, error);
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
      const error = validateBudgetPayload(ctx.body, true);
      if (error) return badRequest(ctx.set, error);
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
    })
    .get("/reports/balances", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getReportsController().balances(ctx);
    })
    .get("/debts", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getDebtsController().list(ctx);
    })
    .post("/debts", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateDebtPayload(ctx.body, false);
      if (error) return badRequest(ctx.set, error);
      return getDebtsController().create(ctx);
    })
    .get("/debts/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getDebtsController().getById(ctx);
    })
    .put("/debts/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateDebtPayload(ctx.body, true);
      if (error) return badRequest(ctx.set, error);
      return getDebtsController().update(ctx);
    })
    .delete("/debts/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getDebtsController().remove(ctx);
    })
    .get("/debts/:id/summary", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getDebtsController().summary(ctx);
    })
    .get("/debts/:id/history", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getDebtsController().history(ctx);
    })
    .get("/debt_transactions", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getDebtTransactionsController().list(ctx);
    })
    .post("/debt_transactions", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateDebtTransactionPayload(ctx.body, false);
      if (error) return badRequest(ctx.set, error);
      return getDebtTransactionsController().create(ctx);
    })
    .get("/debt_transactions/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getDebtTransactionsController().getById(ctx);
    })
    .put("/debt_transactions/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateDebtTransactionPayload(ctx.body, true);
      if (error) return badRequest(ctx.set, error);
      return getDebtTransactionsController().update(ctx);
    })
    .delete("/debt_transactions/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getDebtTransactionsController().remove(ctx);
    })
    .get("/goals", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getGoalsController().list(ctx);
    })
    .post("/goals", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateGoalPayload(ctx.body, false);
      if (error) return badRequest(ctx.set, error);
      return getGoalsController().create(ctx);
    })
    .get("/goals/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getGoalsController().getById(ctx);
    })
    .put("/goals/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateGoalPayload(ctx.body, true);
      if (error) return badRequest(ctx.set, error);
      return getGoalsController().update(ctx);
    })
    .delete("/goals/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getGoalsController().remove(ctx);
    })
    .get("/goals/:id/projection", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getGoalsController().projection(ctx);
    })
    .get("/goals/:id/contributions", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      ctx.query = { ...ctx.query, goalId: ctx.params.id };
      return getGoalsController().listContributions(ctx);
    })
    .post("/goals/:id/contributions", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateGoalContributionPayload(ctx.body, false);
      if (error) return badRequest(ctx.set, error);
      return getGoalsController().createContribution(ctx);
    })
    .put("/goals/:id/contributions/:contributionId", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateGoalContributionPayload(ctx.body, true);
      if (error) return badRequest(ctx.set, error);
      return getGoalsController().updateContribution(ctx);
    })
    .delete("/goals/:id/contributions/:contributionId", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getGoalsController().removeContribution(ctx);
    });
}

import type { AppDeps } from "../../bootstrap/deps";
import { DebtsController } from "../controllers/debts.controller";
import { DebtTransactionsController } from "../controllers/debt_transactions.controller";
import { badRequest } from "../errors";
import { requireAuth } from "../middleware/auth.middleware";
import { validateDebtPayload } from "../validation/debts.validation";
import { validateDebtTransactionPayload } from "../validation/debt_transactions.validation";

export function registerDebtsRoutes(app: any, deps: AppDeps) {
  let debtsController: DebtsController | null = null;
  let debtTransactionsController: DebtTransactionsController | null = null;

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

  app
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
    });
}

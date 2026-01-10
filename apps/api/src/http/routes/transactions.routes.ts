import type { AppDeps } from "../../bootstrap/deps";
import { TransactionsController } from "../controllers/transactions.controller";
import { badRequest } from "../errors";
import { requireAuth } from "../middleware/auth.middleware";
import { validateTransactionPayload } from "../validation/transactions.validation";

export function registerTransactionsRoutes(app: any, deps: AppDeps) {
  let transactionsController: TransactionsController | null = null;

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

  app
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
    .get("/transactions/pending", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getTransactionsController().listPending(ctx);
    })
    .post("/transactions/confirm-batch", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getTransactionsController().confirmBatch(ctx);
    });
}

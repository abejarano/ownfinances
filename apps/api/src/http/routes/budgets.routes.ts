import type { AppDeps } from "../../bootstrap/deps";
import { BudgetsController } from "../controllers/budgets.controller";
import { badRequest } from "../errors";
import { requireAuth } from "../middleware/auth.middleware";
import { validateBudgetPayload } from "../validation/budgets.validation";

export function registerBudgetsRoutes(app: any, deps: AppDeps) {
  let budgetsController: BudgetsController | null = null;

  const getBudgetsController = () => {
    if (!budgetsController) {
      budgetsController = new BudgetsController(
        deps.budgetRepo,
        deps.budgetsService
      );
    }
    return budgetsController;
  };

  app
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
    });
}

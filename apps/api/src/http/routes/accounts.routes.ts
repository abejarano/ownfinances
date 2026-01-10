import type { AppDeps } from "../../bootstrap/deps";
import { AccountsController } from "../controllers/accounts.controller";
import { badRequest } from "../errors";
import { requireAuth } from "../middleware/auth.middleware";
import { validateAccountPayload } from "../validation/accounts.validation";

export function registerAccountsRoutes(app: any, deps: AppDeps) {
  let accountsController: AccountsController | null = null;

  const getAccountsController = () => {
    if (!accountsController) {
      accountsController = new AccountsController(
        deps.accountRepo,
        deps.accountsService
      );
    }
    return accountsController;
  };

  app
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
    });
}

import type { AppDeps } from "../../bootstrap/deps";
import { AuthController } from "../controllers/auth.controller";
import { requireAuth } from "../middleware/auth.middleware";
import { badRequest } from "../errors";
import {
  validateAuthLoginPayload,
  validateAuthLogoutPayload,
  validateAuthRefreshPayload,
  validateAuthRegisterPayload,
} from "../validation/auth.validation";

export function registerAuthRoutes(app: any, deps: AppDeps) {
  const controller = new AuthController(deps.authService);

  app
    .post("/auth/register", async (ctx: any) => {
      const error = validateAuthRegisterPayload(ctx.body);
      if (error) return badRequest(ctx.set, error);
      return controller.register(ctx);
    })
    .post("/auth/login", async (ctx: any) => {
      const error = validateAuthLoginPayload(ctx.body);
      if (error) return badRequest(ctx.set, error);
      return controller.login(ctx);
    })
    .post("/auth/refresh", async (ctx: any) => {
      const error = validateAuthRefreshPayload(ctx.body);
      if (error) return badRequest(ctx.set, error);
      return controller.refresh(ctx);
    })
    .post("/auth/logout", async (ctx: any) => {
      const error = validateAuthLogoutPayload(ctx.body);
      if (error) return badRequest(ctx.set, error);
      return controller.logout(ctx);
    })
    .get("/me", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return controller.me(ctx);
    });
}

import type { AppDeps } from "../../bootstrap/deps";
import { AuthController } from "../controllers/auth.controller";
import { requireAuth } from "../middleware/auth.middleware";

export function registerAuthRoutes(app: any, deps: AppDeps) {
  const controller = new AuthController(deps.authService);

  app
    .post("/auth/register", controller.register)
    .post("/auth/login", controller.login)
    .post("/auth/refresh", controller.refresh)
    .post("/auth/logout", controller.logout)
    .get("/me", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return controller.me(ctx);
    });
}

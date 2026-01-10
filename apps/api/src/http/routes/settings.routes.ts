import type { AppDeps } from "../../bootstrap/deps";
import { SettingsController } from "../controllers/settings.controller";
import { requireAuth } from "../middleware/auth.middleware";

export function registerSettingsRoutes(app: any, deps: AppDeps) {
  const controller = new SettingsController(deps.userSettingsRepo);

  app.group("/settings", (group: any) => {
    group
      .get("/", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.get(ctx);
      })
      .put("/", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.update(ctx);
      });
    return group;
  });
}

import type { AppDeps } from "../../bootstrap/deps";
import { RecurringController } from "../controllers/recurring.controller";
import { requireAuth } from "../middleware/auth.middleware";

export function registerRecurringRoutes(app: any, deps: AppDeps) {
  const controller = new RecurringController(deps.recurringService);

  app.group("/recurring_rules", (group: any) => {
    group
      .get("/", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.list(ctx);
      })
      .post("/", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.create(ctx);
      })
      .delete("/:id", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.delete(ctx);
      })
      .get("/preview", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.preview(ctx);
      })
      .post("/run", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.run(ctx);
      })
      .post("/:id/materialize", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.materialize(ctx);
      })
      .post("/:id/split", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.split(ctx);
      });
    return group;
  });
}

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
      .get("/:id", async (ctx: any) => {
        console.log("getById");
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.getById(ctx);
      })
      .post("/", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.create(ctx);
      })
      .put("/:id", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.update(ctx);
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
      })
      .get("/pending-summary", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.getPendingSummary(ctx);
      })
      .get("/summary-by-month", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.getSummaryByMonth(ctx);
      })
      .get("/catchup", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.getCatchupSummary(ctx);
      });
    return group;
  });
}

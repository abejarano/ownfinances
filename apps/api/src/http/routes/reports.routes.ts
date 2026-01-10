import type { AppDeps } from "../../bootstrap/deps";
import { ReportsController } from "../controllers/reports.controller";
import { requireAuth } from "../middleware/auth.middleware";

export function registerReportsRoutes(app: any, deps: AppDeps) {
  let reportsController: ReportsController | null = null;

  const getReportsController = () => {
    if (!reportsController) {
      reportsController = new ReportsController(deps.reportsService);
    }
    return reportsController;
  };

  app
    .get("/reports/summary", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getReportsController().summary(ctx);
    })
    .get("/reports/balances", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getReportsController().balances(ctx);
    });
}

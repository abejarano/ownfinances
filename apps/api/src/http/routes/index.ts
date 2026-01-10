import type { AppDeps } from "../../bootstrap/deps";
import { registerAccountsRoutes } from "./accounts.routes";
import { registerAuthRoutes } from "./auth.routes";
import { registerBudgetsRoutes } from "./budgets.routes";
import { registerCategoriesRoutes } from "./categories.routes";
import { registerDebtsRoutes } from "./debts.routes";
import { registerGoalsRoutes } from "./goals.routes";
import { registerImportRoutes } from "./imports.routes";
import { registerRecurringRoutes } from "./recurring.routes";
import { registerReportsRoutes } from "./reports.routes";
import { registerTemplateRoutes } from "./templates.routes";
import { registerTransactionsRoutes } from "./transactions.routes";
import { registerWebsocketRoutes } from "./websocket.routes";
import { registerSettingsRoutes } from "./settings.routes";

export function registerRoutes(app: any, deps: AppDeps) {
  registerAuthRoutes(app, deps);
  registerRecurringRoutes(app, deps);
  registerTemplateRoutes(app, deps);
  registerCategoriesRoutes(app, deps);
  registerAccountsRoutes(app, deps);
  registerTransactionsRoutes(app, deps);
  registerBudgetsRoutes(app, deps);
  registerReportsRoutes(app, deps);
  registerDebtsRoutes(app, deps);
  registerGoalsRoutes(app, deps);
  registerImportRoutes(app, deps);
  registerSettingsRoutes(app, deps);
  registerWebsocketRoutes(app);
}

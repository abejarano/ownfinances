import type { AppDeps } from "../../bootstrap/deps";
import { ImportJobsController } from "../controllers/import_jobs.controller";
import { TransactionsImportController } from "../controllers/transactions_import.controller";
import { badRequest } from "../errors";
import { requireAuth } from "../middleware/auth.middleware";
import {
  validateImportPayload,
  validateImportPreviewPayload,
} from "../validation/transactions_import.validation";

export function registerImportRoutes(app: any, deps: AppDeps) {
  let transactionsImportController: TransactionsImportController | null = null;
  let importJobsController: ImportJobsController | null = null;

  const getTransactionsImportController = () => {
    if (!transactionsImportController) {
      transactionsImportController = new TransactionsImportController(
        deps.transactionsImportService
      );
    }
    return transactionsImportController;
  };

  const getImportJobsController = () => {
    if (!importJobsController) {
      importJobsController = new ImportJobsController(deps.importJobRepo);
    }
    return importJobsController;
  };

  app
    .post("/transactions/import/preview", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      // Validadores corren como pre-handler; el controller asume payload valido.
      const previewError = validateImportPreviewPayload({
        accountId: ctx.body?.accountId,
      });
      if (previewError) return badRequest(ctx.set, previewError);
      return getTransactionsImportController().preview(ctx);
    })
    .post("/transactions/import", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      // Validadores corren como pre-handler; el controller asume payload valido.
      const importError = validateImportPayload({
        accountId: ctx.body?.accountId,
      });
      if (importError) return badRequest(ctx.set, importError);
      return getTransactionsImportController().import(ctx);
    })
    .get("/imports/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getImportJobsController().getById(ctx);
    });
}

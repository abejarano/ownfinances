import type { AppDeps } from "../../bootstrap/deps";
import { CategoriesController } from "../controllers/categories.controller";
import { badRequest } from "../errors";
import { requireAuth } from "../middleware/auth.middleware";
import { validateCategoryPayload } from "../validation/categories.validation";

export function registerCategoriesRoutes(app: any, deps: AppDeps) {
  let categoriesController: CategoriesController | null = null;

  const getCategoriesController = () => {
    if (!categoriesController) {
      categoriesController = new CategoriesController(
        deps.categoryRepo,
        deps.categoriesService
      );
    }
    return categoriesController;
  };

  app
    .get("/categories", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getCategoriesController().list(ctx);
    })
    .post("/categories", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateCategoryPayload(ctx.body, false);
      if (error) return badRequest(ctx.set, error);
      return getCategoriesController().create(ctx);
    })
    .get("/categories/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getCategoriesController().getById(ctx);
    })
    .put("/categories/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateCategoryPayload(ctx.body, true);
      if (error) return badRequest(ctx.set, error);
      return getCategoriesController().update(ctx);
    })
    .delete("/categories/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getCategoriesController().remove(ctx);
    });
}

import type { AppDeps } from "../../bootstrap/deps";
import { TemplatesController } from "../controllers/templates.controller";
import { requireAuth } from "../middleware/auth.middleware";
import { badRequest } from "../errors";
import {
  validateTemplatePayload,
} from "../validation/templates.validation";

export function registerTemplateRoutes(app: any, deps: AppDeps) {
  const controller = new TemplatesController(deps.templateService);

  app.group("/templates", (group: any) => {
    group
      .get("/", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.list(ctx);
      })
      .post("/", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        const error = validateTemplatePayload(ctx.body, false);
        if (error) return badRequest(ctx.set, error);
        return controller.create(ctx);
      })
      .get("/:id", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.getById(ctx);
      })
      .put("/:id", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        const error = validateTemplatePayload(ctx.body, true);
        if (error) return badRequest(ctx.set, error);
        return controller.update(ctx);
      })
      .delete("/:id", async (ctx: any) => {
        const auth = await requireAuth(ctx);
        if (auth) return auth;
        return controller.remove(ctx);
      });
    return group;
  });
}

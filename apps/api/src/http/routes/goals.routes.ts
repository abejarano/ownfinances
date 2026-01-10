import type { AppDeps } from "../../bootstrap/deps";
import { GoalsController } from "../controllers/goals.controller";
import { badRequest } from "../errors";
import { requireAuth } from "../middleware/auth.middleware";
import { validateGoalPayload } from "../validation/goals.validation";
import { validateGoalContributionPayload } from "../validation/goal_contributions.validation";

export function registerGoalsRoutes(app: any, deps: AppDeps) {
  let goalsController: GoalsController | null = null;

  const getGoalsController = () => {
    if (!goalsController) {
      goalsController = new GoalsController(
        deps.goalRepo,
        deps.goalsService,
        deps.goalContributionsService,
        deps.goalContributionRepo
      );
    }
    return goalsController;
  };

  app
    .get("/goals", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getGoalsController().list(ctx);
    })
    .post("/goals", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateGoalPayload(ctx.body, false);
      if (error) return badRequest(ctx.set, error);
      return getGoalsController().create(ctx);
    })
    .get("/goals/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getGoalsController().getById(ctx);
    })
    .put("/goals/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateGoalPayload(ctx.body, true);
      if (error) return badRequest(ctx.set, error);
      return getGoalsController().update(ctx);
    })
    .delete("/goals/:id", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getGoalsController().remove(ctx);
    })
    .get("/goals/:id/projection", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getGoalsController().projection(ctx);
    })
    .get("/goals/:id/contributions", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      ctx.query = { ...ctx.query, goalId: ctx.params.id };
      return getGoalsController().listContributions(ctx);
    })
    .post("/goals/:id/contributions", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateGoalContributionPayload(ctx.body, false);
      if (error) return badRequest(ctx.set, error);
      return getGoalsController().createContribution(ctx);
    })
    .put("/goals/:id/contributions/:contributionId", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      const error = validateGoalContributionPayload(ctx.body, true);
      if (error) return badRequest(ctx.set, error);
      return getGoalsController().updateContribution(ctx);
    })
    .delete("/goals/:id/contributions/:contributionId", async (ctx: any) => {
      const authError = await requireAuth(ctx);
      if (authError) return authError;
      return getGoalsController().removeContribution(ctx);
    });
}

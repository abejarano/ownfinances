import type { GoalMongoRepository } from "../../repositories/goal_repository";
import { Goal } from "../../models/goal";
import type { GoalPrimitives } from "../../models/goal";
import type { GoalsService } from "../../services/goals_service";
import type { GoalContributionsService } from "../../services/goal_contributions_service";
import type { GoalContributionMongoRepository } from "../../repositories/goal_contribution_repository";
import { buildGoalsCriteria } from "../criteria/goals.criteria";
import { buildGoalContributionsCriteria } from "../criteria/goal_contributions.criteria";
import { badRequest, notFound } from "../errors";
import type {
  GoalCreatePayload,
  GoalUpdatePayload,
} from "../validation/goals.validation";
import type {
  GoalContributionCreatePayload,
  GoalContributionUpdatePayload,
} from "../validation/goal_contributions.validation";
import { GoalContribution } from "../../models/goal_contribution";
import type { GoalContributionPrimitives } from "../../models/goal_contribution";

export class GoalsController {
  constructor(
    private readonly repo: GoalMongoRepository,
    private readonly service: GoalsService,
    private readonly contributionsService: GoalContributionsService,
    private readonly contributionsRepo: GoalContributionMongoRepository
  ) {}

  async list({
    query,
    userId,
  }: {
    query: Record<string, string | undefined>;
    userId?: string;
  }) {
    const criteria = buildGoalsCriteria(query, userId ?? "");
    const result = await this.repo.list<GoalPrimitives>(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Goal.fromPrimitives(item).toPrimitives()
      ),
    };
  }

  async create({
    body,
    set,
    userId,
  }: {
    body: GoalCreatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { goal } = await this.service.create(userId ?? "", body);
    return goal!;
  }

  async getById({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const goal = await this.repo.one({ userId: userId ?? "", goalId: params.id });
    if (!goal) return notFound(set, "Meta no encontrada");
    return goal.toPrimitives();
  }

  async update({
    params,
    body,
    set,
    userId,
  }: {
    params: { id: string };
    body: GoalUpdatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { goal, error, status } = await this.service.update(
      userId ?? "",
      params.id,
      body
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return goal!;
  }

  async remove({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const { ok, error, status } = await this.service.remove(
      userId ?? "",
      params.id
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return { ok: ok === true };
  }

  async projection({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const result = await this.service.projection(userId ?? "", params.id);
    if (result.error) {
      if (result.status === 404) return notFound(set, result.error);
      return badRequest(set, result.error);
    }
    return result;
  }

  async listContributions({
    query,
    userId,
  }: {
    query: Record<string, string | undefined>;
    userId?: string;
  }) {
    const criteria = buildGoalContributionsCriteria(query, userId ?? "");
    const result = await this.contributionsRepo.list(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        GoalContribution.fromPrimitives(item).toPrimitives()
      ),
    };
  }

  async createContribution({
    params,
    body,
    set,
    userId,
  }: {
    params: { id: string };
    body: GoalContributionCreatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { contribution, error } = await this.contributionsService.create(
      userId ?? "",
      { ...body, goalId: params.id }
    );
    if (error) return badRequest(set, error);
    return contribution!;
  }

  async updateContribution({
    params,
    body,
    set,
    userId,
  }: {
    params: { id: string; contributionId: string };
    body: GoalContributionUpdatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { contribution, error, status } = await this.contributionsService.update(
      userId ?? "",
      params.contributionId,
      body
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return contribution!;
  }

  async removeContribution({
    params,
    set,
    userId,
  }: {
    params: { id: string; contributionId: string };
    set: { status: number };
    userId?: string;
  }) {
    const { ok, error, status } = await this.contributionsService.remove(
      userId ?? "",
      params.contributionId
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return { ok: ok === true };
  }
}

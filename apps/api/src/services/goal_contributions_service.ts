import type { GoalContributionPrimitives } from "../models/goal_contribution";
import { GoalContribution } from "../models/goal_contribution";
import type { GoalContributionMongoRepository } from "../repositories/goal_contribution_repository";
import type { GoalMongoRepository } from "../repositories/goal_repository";
import type { AccountMongoRepository } from "../repositories/account_repository";
import type {
  GoalContributionCreatePayload,
  GoalContributionUpdatePayload,
} from "../http/validation/goal_contributions.validation";

export class GoalContributionsService {
  constructor(
    private readonly contributions: GoalContributionMongoRepository,
    private readonly goals: GoalMongoRepository,
    private readonly accounts: AccountMongoRepository
  ) {}

  async create(userId: string, payload: GoalContributionCreatePayload) {
    const error = await this.validatePayload(userId, payload, false);
    if (error) return { error };

    const date = payload.date ? new Date(payload.date) : new Date();

    const contribution = GoalContribution.create({
      userId,
      goalId: payload.goalId!,
      date,
      amount: payload.amount!,
      accountId: payload.accountId ?? undefined,
      note: payload.note ?? null,
    });

    await this.contributions.upsert(contribution);
    return { contribution: contribution.toPrimitives() };
  }

  async update(
    userId: string,
    id: string,
    payload: GoalContributionUpdatePayload
  ) {
    const existing = await this.contributions.one({
      userId,
      goalContributionId: id,
    });
    if (!existing) {
      return { error: "Aporte no encontrado", status: 404 };
    }

    const existingPrimitives = existing.toPrimitives();
    const merged: GoalContributionPrimitives = {
      ...existingPrimitives,
      ...payload,
      id: existingPrimitives.id ?? existingPrimitives.goalContributionId,
      goalContributionId: existingPrimitives.goalContributionId,
      userId: existingPrimitives.userId,
      date: payload.date ? new Date(payload.date) : existingPrimitives.date,
      updatedAt: new Date(),
    };

    const error = await this.validatePayload(userId, merged, true);
    if (error) return { error };

    await this.contributions.upsert(GoalContribution.fromPrimitives(merged));
    const updated = await this.contributions.one({
      userId,
      goalContributionId: id,
    });
    if (!updated) {
      return { error: "Aporte no encontrado", status: 404 };
    }
    return { contribution: updated.toPrimitives() };
  }

  async remove(userId: string, id: string) {
    const deleted = await this.contributions.delete(userId, id);
    if (!deleted) {
      return { error: "Aporte no encontrado", status: 404 };
    }
    return { ok: true };
  }

  private async validatePayload(
    userId: string,
    payload: GoalContributionCreatePayload | GoalContributionPrimitives,
    isUpdate: boolean
  ): Promise<string | null> {
    if (!isUpdate && !payload.goalId) {
      return "Falta la meta";
    }

    if (payload.goalId) {
      const goal = await this.goals.one({ userId, goalId: payload.goalId });
      if (!goal) return "Meta no encontrada";
    }

    if (payload.accountId) {
      const account = await this.accounts.one({
        userId,
        accountId: payload.accountId,
      });
      if (!account) return "Cuenta no encontrada";
    }

    return null;
  }
}

import type { GoalPrimitives } from "../models/goal";
import { Goal } from "../models/goal";
import type { GoalMongoRepository } from "../repositories/goal_repository";
import type { GoalContributionMongoRepository } from "../repositories/goal_contribution_repository";
import type { TransactionMongoRepository } from "../repositories/transaction_repository";
import type {
  GoalCreatePayload,
  GoalUpdatePayload,
} from "../http/validation/goals.validation";

export class GoalsService {
  constructor(
    private readonly goals: GoalMongoRepository,
    private readonly contributions: GoalContributionMongoRepository,
    private readonly transactions: TransactionMongoRepository
  ) {}

  async create(userId: string, payload: GoalCreatePayload) {
    const goal = Goal.create({
      userId,
      name: payload.name!,
      targetAmount: payload.targetAmount!,
      currency: payload.currency ?? "BRL",
      startDate: new Date(payload.startDate),
      targetDate: payload.targetDate ? new Date(payload.targetDate) : undefined,
      monthlyContribution: payload.monthlyContribution,
      linkedAccountId: payload.linkedAccountId,
      isActive: payload.isActive ?? true,
    });

    await this.goals.upsert(goal);
    return { goal: goal.toPrimitives() };
  }

  async update(userId: string, goalId: string, payload: GoalUpdatePayload) {
    const existing = await this.goals.one({ userId, goalId });
    if (!existing) {
      return { error: "Meta no encontrada", status: 404 };
    }

    const existingPrimitives = existing.toPrimitives();
    const merged: GoalPrimitives = {
      ...existingPrimitives,
      ...payload,
      id: existingPrimitives.id ?? existingPrimitives.goalId,
      goalId: existingPrimitives.goalId,
      userId: existingPrimitives.userId,
      currency: payload.currency ?? existingPrimitives.currency ?? "BRL",
      targetAmount:
        payload.targetAmount ?? existingPrimitives.targetAmount,
      startDate: payload.startDate
        ? new Date(payload.startDate)
        : existingPrimitives.startDate,
      targetDate: payload.targetDate
        ? new Date(payload.targetDate)
        : existingPrimitives.targetDate,
      updatedAt: new Date(),
    };

    const goal = Goal.fromPrimitives(merged);
    await this.goals.upsert(goal);
    return { goal: goal.toPrimitives() };
  }

  async remove(userId: string, goalId: string) {
    const deleted = await this.goals.delete(userId, goalId);
    if (!deleted) {
      return { error: "Meta no encontrada", status: 404 };
    }
    return { ok: true };
  }

  async projection(userId: string, goalId: string) {
    const goal = await this.goals.one({ userId, goalId });
    if (!goal) {
      return { error: "Meta no encontrada", status: 404 };
    }

    const primitive = goal.toPrimitives();
    const contributionTotal = await this.contributions.sumByGoal(userId, {
      goalId,
    });
    const taggedTotal = await this.transactions.sumByGoalTag(userId, goalId);

    const progress = contributionTotal + taggedTotal;
    const remaining = Math.max(0, primitive.targetAmount - progress);

    let monthlyContributionSuggested: number | null = null;
    let targetDateEstimated: Date | null = null;

    if (primitive.monthlyContribution && primitive.monthlyContribution > 0) {
      const months = Math.ceil(remaining / primitive.monthlyContribution);
      if (months > 0) {
        targetDateEstimated = addMonths(new Date(), months);
      }
    }

    if (primitive.targetDate) {
      const monthsToTarget = diffInMonths(new Date(), primitive.targetDate);
      if (monthsToTarget > 0) {
        monthlyContributionSuggested = remaining / monthsToTarget;
      }
    }

    return {
      progress,
      remaining,
      targetAmount: primitive.targetAmount,
      monthlyContributionSuggested,
      targetDateEstimated,
    };
  }
}

function addMonths(date: Date, months: number) {
  return new Date(date.getFullYear(), date.getMonth() + months, date.getDate());
}

function diffInMonths(start: Date, end: Date) {
  return (
    end.getFullYear() * 12 + end.getMonth() - (start.getFullYear() * 12 + start.getMonth())
  );
}

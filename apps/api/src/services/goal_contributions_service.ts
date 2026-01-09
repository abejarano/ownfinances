import type { GoalContributionPrimitives } from "../models/goal_contribution";
import { GoalContribution } from "../models/goal_contribution";
import type { GoalContributionMongoRepository } from "../repositories/goal_contribution_repository";
import type { GoalMongoRepository } from "../repositories/goal_repository";
import type { AccountMongoRepository } from "../repositories/account_repository";
import type { TransactionMongoRepository } from "../repositories/transaction_repository";
import { Transaction, TransactionStatus, TransactionType } from "../models/transaction";
import type {
  GoalContributionCreatePayload,
  GoalContributionUpdatePayload,
} from "../http/validation/goal_contributions.validation";

export class GoalContributionsService {
  constructor(
    private readonly contributions: GoalContributionMongoRepository,
    private readonly goals: GoalMongoRepository,
    private readonly accounts: AccountMongoRepository,
    private readonly transactions: TransactionMongoRepository
  ) {}

  async create(userId: string, payload: GoalContributionCreatePayload) {
    const error = await this.validatePayload(userId, payload, false);
    if (error) return { error };

    const date = payload.date ? new Date(payload.date) : new Date();

    // Obtener la meta para obtener la moneda y linkedAccountId
    const goal = await this.goals.one({ userId, goalId: payload.goalId! });
    if (!goal) {
      return { error: "Meta no encontrada" };
    }
    const goalPrimitives = goal.toPrimitives();
    const currency = goalPrimitives.currency ?? "BRL";

    const contribution = GoalContribution.create({
      userId,
      goalId: payload.goalId!,
      date,
      amount: payload.amount!,
      accountId: payload.accountId ?? undefined,
      note: payload.note ?? null,
    });

    await this.contributions.upsert(contribution);

    // Crear transacción automática si hay accountId
    if (payload.accountId) {
      const note = payload.note
        ? `Aporte para ${goalPrimitives.name}: ${payload.note}`
        : `Aporte para ${goalPrimitives.name}`;

      if (goalPrimitives.linkedAccountId && goalPrimitives.linkedAccountId !== payload.accountId) {
        // Transferencia desde accountId hacia linkedAccountId (cuenta meta)
        const transaction = Transaction.create({
          userId,
          type: TransactionType.Transfer,
          date,
          amount: payload.amount!,
          currency,
          categoryId: null,
          fromAccountId: payload.accountId,
          toAccountId: goalPrimitives.linkedAccountId,
          note,
          tags: null,
          status: TransactionStatus.Cleared,
          clearedAt: new Date(),
        });
        await this.transactions.upsert(transaction);
      } else {
        // Expense desde accountId (no hay cuenta meta o es la misma)
        const transaction = Transaction.create({
          userId,
          type: TransactionType.Expense,
          date,
          amount: payload.amount!,
          currency,
          categoryId: null,
          fromAccountId: payload.accountId,
          toAccountId: null,
          note,
          tags: null,
          status: TransactionStatus.Cleared,
          clearedAt: new Date(),
        });
        await this.transactions.upsert(transaction);
      }
    }

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

import type { BudgetPrimitives } from "../models/budget"
import { Budget } from "../models/budget"
import type { BudgetMongoRepository } from "../repositories/budget_repository"

import type { Result } from "../bootstrap/response"
import type {
  BudgetCreatePayload,
  BudgetUpdatePayload,
} from "../http/validation/budgets.validation"

export class BudgetsService {
  constructor(private readonly budgets: BudgetMongoRepository) {}

  async create(
    userId: string,
    payload: BudgetCreatePayload
  ): Promise<Result<BudgetPrimitives>> {
    const budget = Budget.create({
      userId,
      periodType: payload.periodType!,
      startDate: new Date(payload.startDate!),
      endDate: new Date(payload.endDate!),
      lines: payload.lines ?? [],
    })

    await this.budgets.upsert(budget)
    return { value: budget.toPrimitives(), status: 201 }
  }

  async update(
    userId: string,
    budgetId: string,
    payload: BudgetUpdatePayload
  ): Promise<Result<BudgetPrimitives>> {
    const existing = await this.budgets.one({ userId, budgetId })
    if (!existing) {
      return { error: "Presupuesto no encontrado", status: 404 }
    }

    const existingPrimitives = existing.toPrimitives()
    const merged: BudgetPrimitives = {
      ...existingPrimitives,
      ...payload,
      id: existingPrimitives.id ?? existingPrimitives.budgetId,
      budgetId: existingPrimitives.budgetId,
      userId: existingPrimitives.userId,
      startDate: payload.startDate
        ? new Date(payload.startDate)
        : existingPrimitives.startDate,
      endDate: payload.endDate
        ? new Date(payload.endDate)
        : existingPrimitives.endDate,
      updatedAt: new Date(),
    }

    if (merged.startDate > merged.endDate) {
      return {
        error: "La fecha de fin debe ser mayor a la fecha de inicio",
        status: 400,
      }
    }

    const budget = Budget.fromPrimitives(merged)
    await this.budgets.upsert(budget)

    return { value: budget.toPrimitives(), status: 200 }
  }

  async remove(userId: string, budgetId: string) {
    const deleted = await this.budgets.delete(userId, budgetId)
    if (!deleted) {
      return { error: "Presupuesto no encontrado", status: 404 }
    }
    return { ok: true }
  }
}

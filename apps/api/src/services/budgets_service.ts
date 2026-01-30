import type {
  BudgetCategoryPlan,
  BudgetPlanEntry,
  BudgetPrimitives,
} from "@desquadra/database"
import { Budget } from "@desquadra/database"
import type { BudgetMongoRepository } from "@desquadra/database"
import { createMongoId } from "@desquadra/database"

import type { Result } from "../bootstrap/response"
import type {
  BudgetCreatePayload,
  BudgetCategoryPlanPayload,
  BudgetUpdatePayload,
} from "../http/validation/budgets.validation"
import { computePeriodRange, getRangeAnchorDate } from "../shared/dates"

export class BudgetsService {
  constructor(private readonly budgets: BudgetMongoRepository) {}

  async create(
    userId: string,
    payload: BudgetCreatePayload
  ): Promise<Result<BudgetPrimitives>> {
    const periodType = payload.periodType ?? "monthly"

    // Enforce monthly only
    if (periodType !== "monthly") {
      return {
        error: "Solo se permiten presupuestos mensuales",
        status: 400,
      }
    }

    const startRange = computePeriodRange("monthly", payload.startDate!)
    const endRange = computePeriodRange("monthly", payload.endDate!)
    const anchorDate = getRangeAnchorDate(startRange)

    if (startRange.start.getTime() !== endRange.start.getTime()) {
      return {
        error: "La fecha de inicio y fin deben pertenecer al mismo mes",
        status: 400,
      }
    }

    // Check for duplicates
    const existing = await this.budgets.one({
      userId,
      periodType: "monthly",
      startDate: { $lte: anchorDate } as any,
      endDate: { $gte: anchorDate } as any,
    })

    if (existing) {
      return { value: existing.toPrimitives(), status: 200 }
    }

    const budget = Budget.create({
      userId,
      periodType: "monthly",
      startDate: startRange.start,
      endDate: startRange.end,
      categories: this.normalizeCategories(payload.categories),
      debtPayments: payload.debtPayments ?? [],
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
      categories: payload.categories
        ? this.normalizeCategories(payload.categories)
        : existingPrimitives.categories,
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

  async removeLine(
    userId: string,
    periodType: string,
    referenceDate: Date,
    categoryId: string
  ): Promise<Result<BudgetPrimitives>> {
    const existing = await this.budgets.one({
      userId,
      periodType,
      startDate: { $lte: referenceDate } as any,
      endDate: { $gte: referenceDate } as any,
    })

    if (!existing) {
      return {
        error: "Presupuesto no encontrado para este periodo",
        status: 404,
      }
    }

    const primitives = existing.toPrimitives()
    const newCategories = primitives.categories.filter(
      (category) => category.categoryId !== categoryId
    )

    if (newCategories.length === primitives.categories.length) {
      return { value: primitives, status: 200 }
    }

    const updated = Budget.fromPrimitives({
      ...primitives,
      categories: newCategories,
      updatedAt: new Date(),
    })

    await this.budgets.upsert(updated)
    return { value: updated.toPrimitives(), status: 200 }
  }

  private normalizeCategories(
    categories?: BudgetCategoryPlanPayload[]
  ): BudgetCategoryPlan[] {
    if (!categories || categories.length === 0) return []
    return categories
      .map((category) => {
        const entries = (category.entries ?? []).map((entry) =>
          this.normalizeEntry(entry)
        )
        const plannedTotal: Record<string, number> = {}
        for (const entry of entries) {
          plannedTotal[entry.currency] =
            (plannedTotal[entry.currency] || 0) + entry.amount
        }
        return {
          categoryId: category.categoryId,
          plannedTotal,
          entries,
        }
      })
      .filter((category) => category.entries.length > 0)
  }

  private normalizeEntry(entry: {
    entryId?: string
    amount: number
    currency: string
    description?: string
    createdAt?: string | Date
  }): BudgetPlanEntry {
    return {
      entryId: entry.entryId ?? createMongoId(),
      amount: entry.amount,
      currency: entry.currency,
      description: entry.description ?? null,
      createdAt: entry.createdAt ? new Date(entry.createdAt) : new Date(),
    }
  }
}

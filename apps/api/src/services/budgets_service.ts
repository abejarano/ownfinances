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
    const periodType = payload.periodType ?? "monthly"

    // Enforce monthly only
    if (periodType !== "monthly") {
      return {
        error: "Solo se permiten presupuestos mensuales",
        status: 400,
      }
    }

    const startDate = new Date(payload.startDate!)
    const endDate = new Date(payload.endDate!)

    // Validate start/end dates covers full month
    // We assume startDate must be 1st day and endDate must be last day
    const startOfMonth = new Date(startDate.getFullYear(), startDate.getMonth(), 1)
    const endOfMonth = new Date(startDate.getFullYear(), startDate.getMonth() + 1, 0, 23, 59, 59, 999)

    // A simple check: ensure they match same month and year
    if (
      startDate.getFullYear() !== endDate.getFullYear() ||
      startDate.getMonth() !== endDate.getMonth()
    ) {
        return {
          error: "La fecha de inicio y fin deben pertenecer al mismo mes",
          status: 400,
        }
    }

    // Check for duplicates
    const existing = await this.budgets.one({
      userId,
      periodType: "monthly",
      startDate: startOfMonth,
      endDate: endOfMonth,
    })

    if (existing) {
      return { value: existing.toPrimitives(), status: 200 }
    }

    const budget = Budget.create({
      userId,
      periodType: "monthly",
      startDate: startOfMonth,
      endDate: endOfMonth,
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

  async removeLine(
    userId: string,
    periodType: string,
    startDate: Date,
    endDate: Date,
    categoryId: string
  ): Promise<Result<BudgetPrimitives>> {
    const existing = await this.budgets.one({
      userId,
      periodType,
      startDate,
      endDate,
    })

    if (!existing) {
      return { error: "Presupuesto no encontrado para este periodo", status: 404 }
    }

    const primitives = existing.toPrimitives()
    const newLines = primitives.lines.filter(
      (line) => line.categoryId !== categoryId
    )

    if (newLines.length === primitives.lines.length) {
      // Category not found in lines, treating as success (idempotent) or error?
      // Ticket says "noop (200 ok)".
      return { value: primitives, status: 200 }
    }

    const updated = Budget.fromPrimitives({
      ...primitives,
      lines: newLines,
      updatedAt: new Date(),
    })

    await this.budgets.upsert(updated)
    return { value: updated.toPrimitives(), status: 200 }
  }
}

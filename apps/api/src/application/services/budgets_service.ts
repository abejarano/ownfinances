import { ObjectId } from "mongodb";
import type { BudgetPrimitives, BudgetPeriodType } from "../../domain/budget";
import { Budget } from "../../domain/budget";
import type { BudgetMongoRepository } from "../../repositories/budget_repository";

export class BudgetsService {
  constructor(private readonly budgets: BudgetMongoRepository) {}

  async create(userId: string, payload: Partial<BudgetPrimitives>) {
    const error = this.validate(payload, false);
    if (error) return { error };

    const now = new Date();
    const newId = new ObjectId().toHexString();
    const budget = new Budget({
      id: newId,
      budgetId: newId,
      userId,
      periodType: payload.periodType!,
      startDate: new Date(payload.startDate!),
      endDate: new Date(payload.endDate!),
      lines: payload.lines ?? [],
      createdAt: now,
      updatedAt: now,
    });

    await this.budgets.upsert(budget);
    return { budget: budget.toPrimitives() };
  }

  async update(userId: string, budgetId: string, payload: Partial<BudgetPrimitives>) {
    const existing = await this.budgets.one({ userId, budgetId });
    if (!existing) {
      return { error: "Presupuesto no encontrado", status: 404 };
    }

    const merged: BudgetPrimitives = {
      ...existing,
      ...payload,
      id: existing.id ?? existing.budgetId,
      budgetId: existing.budgetId,
      userId: existing.userId,
      startDate: payload.startDate ? new Date(payload.startDate) : existing.startDate,
      endDate: payload.endDate ? new Date(payload.endDate) : existing.endDate,
      updatedAt: new Date(),
    };

    const error = this.validate(merged, true);
    if (error) return { error };

    const budget = Budget.fromPrimitives(merged);
    await this.budgets.upsert(budget);
    return { budget: budget.toPrimitives() };
  }

  async remove(userId: string, budgetId: string) {
    const deleted = await this.budgets.delete(userId, budgetId);
    if (!deleted) {
      return { error: "Presupuesto no encontrado", status: 404 };
    }
    return { ok: true };
  }

  private validate(payload: Partial<BudgetPrimitives>, isUpdate: boolean) {
    if (!isUpdate && !payload.periodType) {
      return "Falta el periodo";
    }
    if (payload.periodType && !isBudgetPeriod(payload.periodType)) {
      return "Periodo invalido";
    }
    if (!isUpdate && !payload.startDate) {
      return "Falta la fecha de inicio";
    }
    if (!isUpdate && !payload.endDate) {
      return "Falta la fecha de fin";
    }
    if (payload.startDate && payload.endDate) {
      const start = new Date(payload.startDate);
      const end = new Date(payload.endDate);
      if (start > end) {
        return "La fecha de fin debe ser mayor a la fecha de inicio";
      }
    }
    if (payload.lines) {
      const invalid = payload.lines.some(
        (line) => !line.categoryId || line.plannedAmount < 0,
      );
      if (invalid) {
        return "Lineas invalidas en el presupuesto";
      }
    }
    return null;
  }
}

function isBudgetPeriod(value: string): value is BudgetPeriodType {
  return value === "monthly" || value === "quarterly" || value === "semiannual" || value === "annual";
}

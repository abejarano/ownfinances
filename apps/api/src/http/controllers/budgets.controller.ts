import type { BudgetMongoRepository } from "../../repositories/budget_repository";
import { Budget } from "../../domain/budget";
import type { BudgetsService } from "../../application/services/budgets_service";
import type { BudgetPrimitives, BudgetPeriodType } from "../../domain/budget";
import { buildBudgetsCriteria } from "../criteria/budgets.criteria";
import { badRequest, notFound } from "../errors";
import { computePeriodRange } from "../../application/services/reports_service";

export class BudgetsController {
  constructor(
    private readonly repo: BudgetMongoRepository,
    private readonly service: BudgetsService,
  ) {}

  list = async ({ query, userId }: { query: Record<string, string | undefined>; userId?: string }) => {
    const criteria = buildBudgetsCriteria(query, userId ?? "");
    const result = await this.repo.list(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Budget.fromPrimitives(item).toPrimitives(),
      ),
    };
  };

  create = async ({ body, set, userId }: { body: unknown; set: { status: number }; userId?: string }) => {
    const { budget, error } = await this.service.create(
      userId ?? "",
      body as Record<string, unknown>,
    );
    if (error) return badRequest(set, error);
    return budget!;
  };

  getById = async ({ params, set, userId }: { params: { id: string }; set: { status: number }; userId?: string }) => {
    const budget = await this.repo.one({ userId: userId ?? "", budgetId: params.id });
    if (!budget) return notFound(set, "Presupuesto no encontrado");
    return Budget.fromPrimitives(budget).toPrimitives();
  };

  update = async ({ params, body, set, userId }: { params: { id: string }; body: unknown; set: { status: number }; userId?: string }) => {
    const { budget, error, status } = await this.service.update(
      userId ?? "",
      params.id,
      body as Record<string, unknown>,
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return budget!;
  };

  remove = async ({ params, set, userId }: { params: { id: string }; set: { status: number }; userId?: string }) => {
    const { ok, error, status } = await this.service.remove(userId ?? "", params.id);
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return { ok: ok === true };
  };

  current = async ({ query, userId, set }: { query: Record<string, string | undefined>; userId?: string; set: { status: number } }) => {
    const period = query.period as BudgetPeriodType | undefined;
    const date = query.date ? new Date(query.date) : new Date();
    if (!period) return badRequest(set, "Falta el periodo");
    if (Number.isNaN(date.getTime())) return badRequest(set, "Fecha invalida");

    const range = computePeriodRange(period, date);
    const budget = await this.repo.one({
      userId: userId ?? "",
      periodType: period,
      startDate: range.start,
      endDate: range.end,
    });

    if (!budget) {
      return { budget: null, range };
    }

    return { budget: Budget.fromPrimitives(budget).toPrimitives(), range };
  };
}

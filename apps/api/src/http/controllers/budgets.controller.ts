import type { BudgetMongoRepository } from "../../repositories/budget_repository";
import { Budget } from "../../models/budget";
import type { BudgetsService } from "../../services/budgets_service";
import type { BudgetPrimitives, BudgetPeriodType } from "../../models/budget";
import { buildBudgetsCriteria } from "../criteria/budgets.criteria";
import { badRequest, notFound } from "../errors";
import { computePeriodRange } from "../../services/reports_service";
import type {
  BudgetCreatePayload,
  BudgetUpdatePayload,
} from "../validation/budgets.validation";

export class BudgetsController {
  constructor(
    private readonly repo: BudgetMongoRepository,
    private readonly service: BudgetsService
  ) {}

  async list({
    query,
    userId,
  }: {
    query: Record<string, string | undefined>;
    userId?: string;
  }) {
    const criteria = buildBudgetsCriteria(query, userId ?? "");
    const result = await this.repo.list<BudgetPrimitives>(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Budget.fromPrimitives(item).toPrimitives()
      ),
    };
  }

  async create({
    body,
    set,
    userId,
  }: {
    body: BudgetCreatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { budget } = await this.service.create(userId ?? "", body);
    return budget!;
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
    const budget = await this.repo.one({
      userId: userId ?? "",
      budgetId: params.id,
    });
    if (!budget) return notFound(set, "Presupuesto no encontrado");
    return budget.toPrimitives();
  }

  async update({
    params,
    body,
    set,
    userId,
  }: {
    params: { id: string };
    body: BudgetUpdatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { budget, error, status } = await this.service.update(
      userId ?? "",
      params.id,
      body
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return budget!;
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

  async current({
    query,
    userId,
    set,
  }: {
    query: Record<string, string | undefined>;
    userId?: string;
    set: { status: number };
  }) {
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

    return { budget: budget.toPrimitives(), range };
  }
}

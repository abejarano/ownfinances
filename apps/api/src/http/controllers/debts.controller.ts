import type { DebtMongoRepository } from "../../repositories/debt_repository";
import { Debt } from "../../models/debt";
import type { DebtPrimitives } from "../../models/debt";
import type { DebtsService } from "../../services/debts_service";
import { buildDebtsCriteria } from "../criteria/debts.criteria";
import { badRequest, notFound } from "../errors";
import type {
  DebtCreatePayload,
  DebtUpdatePayload,
} from "../validation/debts.validation";

export class DebtsController {
  constructor(
    private readonly repo: DebtMongoRepository,
    private readonly service: DebtsService
  ) {}

  async list({
    query,
    userId,
  }: {
    query: Record<string, string | undefined>;
    userId?: string;
  }) {
    const criteria = buildDebtsCriteria(query, userId ?? "");
    const result = await this.repo.list<DebtPrimitives>(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Debt.fromPrimitives(item).toPrimitives()
      ),
    };
  }

  async create({
    body,
    set,
    userId,
  }: {
    body: DebtCreatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { debt } = await this.service.create(userId ?? "", body);
    return debt!;
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
    const debt = await this.repo.one({ userId: userId ?? "", debtId: params.id });
    if (!debt) return notFound(set, "Deuda no encontrada");
    return debt.toPrimitives();
  }

  async update({
    params,
    body,
    set,
    userId,
  }: {
    params: { id: string };
    body: DebtUpdatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { debt, error, status } = await this.service.update(
      userId ?? "",
      params.id,
      body
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return debt!;
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

  async summary({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const result = await this.service.summary(userId ?? "", params.id);
    if (result.error) {
      if (result.status === 404) return notFound(set, result.error);
      return badRequest(set, result.error);
    }
    return result;
  }
}

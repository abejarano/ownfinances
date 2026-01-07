import type { DebtTransactionMongoRepository } from "../../repositories/debt_transaction_repository";
import { DebtTransaction } from "../../models/debt_transaction";
import type { DebtTransactionPrimitives } from "../../models/debt_transaction";
import type { DebtTransactionsService } from "../../services/debt_transactions_service";
import { buildDebtTransactionsCriteria } from "../criteria/debt_transactions.criteria";
import { badRequest, notFound } from "../errors";
import type {
  DebtTransactionCreatePayload,
  DebtTransactionUpdatePayload,
} from "../validation/debt_transactions.validation";

export class DebtTransactionsController {
  constructor(
    private readonly repo: DebtTransactionMongoRepository,
    private readonly service: DebtTransactionsService
  ) {}

  async list({
    query,
    userId,
  }: {
    query: Record<string, string | undefined>;
    userId?: string;
  }) {
    const criteria = buildDebtTransactionsCriteria(query, userId ?? "");
    const result = await this.repo.list<DebtTransactionPrimitives>(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        DebtTransaction.fromPrimitives(item).toPrimitives()
      ),
    };
  }

  async create({
    body,
    set,
    userId,
  }: {
    body: DebtTransactionCreatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { debtTransaction, error } = await this.service.create(
      userId ?? "",
      body
    );
    if (error) return badRequest(set, error);
    return debtTransaction!;
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
    const item = await this.repo.one({
      userId: userId ?? "",
      debtTransactionId: params.id,
    });
    if (!item) return notFound(set, "Movimiento no encontrado");
    return item.toPrimitives();
  }

  async update({
    params,
    body,
    set,
    userId,
  }: {
    params: { id: string };
    body: DebtTransactionUpdatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { debtTransaction, error, status } = await this.service.update(
      userId ?? "",
      params.id,
      body
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return debtTransaction!;
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
}

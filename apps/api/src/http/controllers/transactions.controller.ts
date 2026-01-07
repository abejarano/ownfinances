import type { TransactionMongoRepository } from "../../repositories/transaction_repository";
import type { TransactionsService } from "../../services/transactions_service";
import { Transaction } from "../../models/transaction";
import type { TransactionPrimitives } from "../../models/transaction";
import { buildTransactionsCriteria } from "../criteria/transactions.criteria";
import { badRequest, notFound } from "../errors";
import type {
  TransactionCreatePayload,
  TransactionUpdatePayload,
} from "../validation/transactions.validation";
import type { ReportsService } from "../../services/reports_service";

export class TransactionsController {
  constructor(
    private readonly repo: TransactionMongoRepository,
    private readonly service: TransactionsService,
    private readonly reports: ReportsService
  ) {}

  async list({
    query,
    userId,
  }: {
    query: Record<string, string | undefined>;
    userId?: string;
  }) {
    const criteria = buildTransactionsCriteria(query, userId ?? "");
    const result = await this.repo.list<TransactionPrimitives>(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Transaction.fromPrimitives(item).toPrimitives()
      ),
    };
  }

  async create({
    body,
    set,
    userId,
    query,
  }: {
    body: TransactionCreatePayload;
    set: { status: number };
    userId?: string;
    query?: Record<string, string | undefined>;
  }) {
    const { transaction, error } = await this.service.create(
      userId ?? "",
      body
    );
    if (error) return badRequest(set, error);
    const impact = await this._impactFor(
      userId ?? "",
      transaction!,
      query
    );
    return impact ? { ...transaction!, impact } : transaction!;
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
    const transaction = await this.repo.one({
      userId: userId ?? "",
      transactionId: params.id,
    });
    if (!transaction || transaction.toPrimitives().deletedAt) {
      return notFound(set, "Transacao nao encontrada");
    }
    return transaction.toPrimitives();
  }

  async update({
    params,
    body,
    set,
    userId,
    query,
  }: {
    params: { id: string };
    body: TransactionUpdatePayload;
    set: { status: number };
    userId?: string;
    query?: Record<string, string | undefined>;
  }) {
    const { transaction, error, status } = await this.service.update(
      userId ?? "",
      params.id,
      body
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    const impact = await this._impactFor(
      userId ?? "",
      transaction!,
      query
    );
    return impact ? { ...transaction!, impact } : transaction!;
  }

  async remove({
    params,
    set,
    userId,
    query,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
    query?: Record<string, string | undefined>;
  }) {
    const existing = await this.repo.one({
      userId: userId ?? "",
      transactionId: params.id,
    });
    const { ok, error, status } = await this.service.remove(
      userId ?? "",
      params.id
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    const impact = existing
      ? await this._impactFor(userId ?? "", existing.toPrimitives(), query)
      : null;
    return impact ? { ok: ok === true, impact } : { ok: ok === true };
  }

  async clear({
    params,
    set,
    userId,
    query,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
    query?: Record<string, string | undefined>;
  }) {
    const { transaction, error, status } = await this.service.clear(
      userId ?? "",
      params.id
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    const impact = await this._impactFor(
      userId ?? "",
      transaction!,
      query
    );
    return impact ? { ...transaction!, impact } : transaction!;
  }

  async restore({
    params,
    set,
    userId,
    query,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
    query?: Record<string, string | undefined>;
  }) {
    const { transaction, error, status } = await this.service.restore(
      userId ?? "",
      params.id
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    const impact = await this._impactFor(
      userId ?? "",
      transaction!,
      query
    );
    return impact ? { ...transaction!, impact } : transaction!;
  }

  private async _impactFor(
    userId: string,
    transaction: TransactionPrimitives,
    query?: Record<string, string | undefined>
  ) {
    if (query?.impact !== "true") return null;
    const period = (query.period as any) ?? "monthly";
    const date = transaction.date ?? new Date();
    const summary = await this.reports.summary(userId, period, date);
    const balances = await this.reports.balances(userId, period, date);
    return {
      summary,
      balances: balances.balances,
      range: balances.range,
    };
  }
}

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

export class TransactionsController {
  constructor(
    private readonly repo: TransactionMongoRepository,
    private readonly service: TransactionsService
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
  }: {
    body: TransactionCreatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { transaction, error } = await this.service.create(
      userId ?? "",
      body
    );
    if (error) return badRequest(set, error);
    return transaction!;
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
    if (!transaction) return notFound(set, "Transaccion no encontrada");
    return transaction.toPrimitives();
  }

  async update({
    params,
    body,
    set,
    userId,
  }: {
    params: { id: string };
    body: TransactionUpdatePayload;
    set: { status: number };
    userId?: string;
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
    return transaction!;
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
    const deleted = await this.repo.delete(userId ?? "", params.id);
    if (!deleted) return notFound(set, "Transaccion no encontrada");
    return { ok: true };
  }

  async clear({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const { transaction, error, status } = await this.service.clear(
      userId ?? "",
      params.id
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return transaction!;
  }
}

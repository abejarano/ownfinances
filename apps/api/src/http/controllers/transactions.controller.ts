import type { TransactionMongoRepository } from "../../repositories/transaction_repository";
import type { TransactionsService } from "../../application/services/transactions_service";
import { Transaction } from "../../domain/transaction";
import { buildTransactionsCriteria } from "../criteria/transactions.criteria";
import { badRequest, notFound } from "../errors";

export class TransactionsController {
  constructor(
    private readonly repo: TransactionMongoRepository,
    private readonly service: TransactionsService,
    private readonly userId: string,
  ) {}

  list = async ({ query }: { query: Record<string, string | undefined> }) => {
    const criteria = buildTransactionsCriteria(query, this.userId);
    const result = await this.repo.list(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Transaction.fromPrimitives(item).toPrimitives(),
      ),
    };
  };

  create = async ({ body, set }: { body: unknown; set: { status: number } }) => {
    const { transaction, error } = await this.service.create(
      body as Record<string, unknown>,
    );
    if (error) return badRequest(set, error);
    return transaction!;
  };

  getById = async ({ params, set }: { params: { id: string }; set: { status: number } }) => {
    const transaction = await this.repo.one({ userId: this.userId, transactionId: params.id });
    if (!transaction) return notFound(set, "Transaccion no encontrada");
    return Transaction.fromPrimitives(transaction).toPrimitives();
  };

  update = async ({ params, body, set }: { params: { id: string }; body: unknown; set: { status: number } }) => {
    const { transaction, error, status } = await this.service.update(
      params.id,
      body as Record<string, unknown>,
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return Transaction.fromPrimitives(transaction!).toPrimitives();
  };

  remove = async ({ params, set }: { params: { id: string }; set: { status: number } }) => {
    const deleted = await this.repo.delete(this.userId, params.id);
    if (!deleted) return notFound(set, "Transaccion no encontrada");
    return { ok: true };
  };

  clear = async ({ params, set }: { params: { id: string }; set: { status: number } }) => {
    const { transaction, error, status } = await this.service.clear(params.id);
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return Transaction.fromPrimitives(transaction!).toPrimitives();
  };
}

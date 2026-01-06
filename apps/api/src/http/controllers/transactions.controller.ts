import type { TransactionMongoRepository } from "../../repositories/transaction_repository";
import type { TransactionsService } from "../../application/services/transactions_service";
import { Transaction } from "../../domain/transaction";
import { buildTransactionsCriteria } from "../criteria/transactions.criteria";
import { badRequest, notFound } from "../errors";

export class TransactionsController {
  constructor(
    private readonly repo: TransactionMongoRepository,
    private readonly service: TransactionsService,
  ) {}

  list = async ({ query, userId }: { query: Record<string, string | undefined>; userId?: string }) => {
    const criteria = buildTransactionsCriteria(query, userId ?? "");
    const result = await this.repo.list(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Transaction.fromPrimitives(item).toPrimitives(),
      ),
    };
  };

  create = async ({ body, set, userId }: { body: unknown; set: { status: number }; userId?: string }) => {
    const { transaction, error } = await this.service.create(
      userId ?? "",
      body as Record<string, unknown>,
    );
    if (error) return badRequest(set, error);
    return transaction!;
  };

  getById = async ({ params, set, userId }: { params: { id: string }; set: { status: number }; userId?: string }) => {
    const transaction = await this.repo.one({ userId: userId ?? "", transactionId: params.id });
    if (!transaction) return notFound(set, "Transaccion no encontrada");
    return Transaction.fromPrimitives(transaction).toPrimitives();
  };

  update = async ({ params, body, set, userId }: { params: { id: string }; body: unknown; set: { status: number }; userId?: string }) => {
    const { transaction, error, status } = await this.service.update(
      userId ?? "",
      params.id,
      body as Record<string, unknown>,
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return Transaction.fromPrimitives(transaction!).toPrimitives();
  };

  remove = async ({ params, set, userId }: { params: { id: string }; set: { status: number }; userId?: string }) => {
    const deleted = await this.repo.delete(userId ?? "", params.id);
    if (!deleted) return notFound(set, "Transaccion no encontrada");
    return { ok: true };
  };

  clear = async ({ params, set, userId }: { params: { id: string }; set: { status: number }; userId?: string }) => {
    const { transaction, error, status } = await this.service.clear(userId ?? "", params.id);
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return Transaction.fromPrimitives(transaction!).toPrimitives();
  };
}

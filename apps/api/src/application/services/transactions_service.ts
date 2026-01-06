import type { TransactionPrimitives, TransactionStatus, TransactionType } from "../../domain/transaction";
import { Transaction } from "../../domain/transaction";
import type { TransactionMongoRepository } from "../../repositories/transaction_repository";
import type { AccountMongoRepository } from "../../repositories/account_repository";
import { ObjectId } from "mongodb";

export class TransactionsService {
  constructor(
    private readonly transactions: TransactionMongoRepository,
    private readonly accounts: AccountMongoRepository,
    private readonly userId: string,
  ) {}

  async create(payload: Partial<TransactionPrimitives>) {
    const error = await this.validatePayload(payload, false);
    if (error) return { error };

    const now = new Date();
    const newId = new ObjectId().toHexString();
    const date = payload.date ? new Date(payload.date) : new Date();
    const currency =
      payload.currency ??
      (await this.resolveCurrency(payload)) ??
      "BRL";

    const transaction = new Transaction({
      id: newId,
      transactionId: newId,
      userId: this.userId,
      type: payload.type!,
      date,
      amount: payload.amount!,
      currency,
      categoryId: payload.categoryId ?? null,
      fromAccountId: payload.fromAccountId ?? null,
      toAccountId: payload.toAccountId ?? null,
      note: payload.note ?? null,
      tags: payload.tags ?? null,
      status: payload.status ?? "pending",
      clearedAt: payload.status === "cleared" ? now : null,
      createdAt: now,
      updatedAt: now,
    });

    await this.transactions.upsert(transaction);
    return { transaction: transaction.toPrimitives() };
  }

  async update(id: string, payload: Partial<TransactionPrimitives>) {
    const existing = await this.transactions.one({ userId: this.userId, transactionId: id });
    if (!existing) {
      return { error: "Transaccion no encontrada", status: 404 };
    }

    const merged: TransactionPrimitives = {
      ...existing,
      ...payload,
      id: existing.id ?? existing.transactionId,
      transactionId: existing.transactionId,
      userId: existing.userId,
      date: payload.date ? new Date(payload.date) : existing.date,
      updatedAt: new Date(),
    };

    const error = await this.validatePayload(merged, true);
    if (error) return { error };

    if (merged.status === "cleared" && !merged.clearedAt) {
      merged.clearedAt = new Date();
    }
    if (merged.status === "pending") {
      merged.clearedAt = null;
    }

    await this.transactions.upsert(Transaction.fromPrimitives(merged));
    const updated = await this.transactions.one({ userId: this.userId, transactionId: id });
    return { transaction: updated! };
  }

  async clear(id: string) {
    const existing = await this.transactions.one({ userId: this.userId, transactionId: id });
    if (!existing) {
      return { error: "Transaccion no encontrada", status: 404 };
    }

    const cleared = Transaction.fromPrimitives({
      ...existing,
      id: existing.id ?? existing.transactionId,
      status: "cleared",
      clearedAt: new Date(),
      updatedAt: new Date(),
    });

    await this.transactions.upsert(cleared);
    const updated = await this.transactions.one({ userId: this.userId, transactionId: id });
    return { transaction: updated! };
  }

  private async validatePayload(
    payload: Partial<TransactionPrimitives>,
    isUpdate: boolean,
  ): Promise<string | null> {
    if (!payload.type && !isUpdate) {
      return "Falta el tipo de transaccion";
    }
    if (payload.type && !isTransactionType(payload.type)) {
      return "Tipo de transaccion invalido";
    }
    if (payload.amount !== undefined && payload.amount <= 0) {
      return "El monto debe ser mayor que 0";
    }
    if (!isUpdate && payload.amount === undefined) {
      return "Falta el monto";
    }
    if (payload.status && !isTransactionStatus(payload.status)) {
      return "Estado invalido";
    }

    const type = payload.type;
    if (type === "income") {
      if (!payload.categoryId) return "Falta elegir una categoria";
      if (!payload.toAccountId) return "Falta elegir una cuenta";
    }
    if (type === "expense") {
      if (!payload.categoryId) return "Falta elegir una categoria";
      if (!payload.fromAccountId) return "Falta elegir una cuenta";
    }
    if (type === "transfer") {
      if (!payload.fromAccountId || !payload.toAccountId) {
        return "Falta elegir cuenta de origen o destino";
      }
      if (payload.categoryId) {
        return "Las transferencias no tienen categoria";
      }
    }

    if (payload.date) {
      const date = new Date(payload.date);
      if (Number.isNaN(date.getTime())) {
        return "Fecha invalida";
      }
    }

    if (payload.fromAccountId) {
      const account = await this.accounts.one({
        userId: this.userId,
        accountId: payload.fromAccountId,
      });
      if (!account) {
        return "Cuenta de origen no encontrada";
      }
    }
    if (payload.toAccountId) {
      const account = await this.accounts.one({
        userId: this.userId,
        accountId: payload.toAccountId,
      });
      if (!account) {
        return "Cuenta de destino no encontrada";
      }
    }

    return null;
  }

  private async resolveCurrency(payload: Partial<TransactionPrimitives>) {
    if (payload.type === "income" && payload.toAccountId) {
      const account = await this.accounts.one({
        userId: this.userId,
        accountId: payload.toAccountId,
      });
      return account?.currency;
    }
    if (payload.type === "expense" && payload.fromAccountId) {
      const account = await this.accounts.one({
        userId: this.userId,
        accountId: payload.fromAccountId,
      });
      return account?.currency;
    }
    if (payload.type === "transfer" && payload.fromAccountId) {
      const account = await this.accounts.one({
        userId: this.userId,
        accountId: payload.fromAccountId,
      });
      return account?.currency;
    }
    return undefined;
  }
}

function isTransactionType(value: string): value is TransactionType {
  return value === "income" || value === "expense" || value === "transfer";
}

function isTransactionStatus(value: string): value is TransactionStatus {
  return value === "pending" || value === "cleared";
}

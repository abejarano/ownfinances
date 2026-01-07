import type { DebtTransactionPrimitives } from "../models/debt_transaction";
import { DebtTransaction } from "../models/debt_transaction";
import type { DebtMongoRepository } from "../repositories/debt_repository";
import type { DebtTransactionMongoRepository } from "../repositories/debt_transaction_repository";
import type { AccountMongoRepository } from "../repositories/account_repository";
import type {
  DebtTransactionCreatePayload,
  DebtTransactionUpdatePayload,
} from "../http/validation/debt_transactions.validation";

export class DebtTransactionsService {
  constructor(
    private readonly debtTransactions: DebtTransactionMongoRepository,
    private readonly debts: DebtMongoRepository,
    private readonly accounts: AccountMongoRepository
  ) {}

  async create(userId: string, payload: DebtTransactionCreatePayload) {
    const error = await this.validatePayload(userId, payload, false);
    if (error) return { error };

    const date = payload.date ? new Date(payload.date) : new Date();

    const tx = DebtTransaction.create({
      userId,
      debtId: payload.debtId!,
      date,
      type: payload.type!,
      amount: payload.amount!,
      accountId: payload.accountId ?? undefined,
      note: payload.note ?? null,
    });

    await this.debtTransactions.upsert(tx);
    return { debtTransaction: tx.toPrimitives() };
  }

  async update(
    userId: string,
    id: string,
    payload: DebtTransactionUpdatePayload
  ) {
    const existing = await this.debtTransactions.one({
      userId,
      debtTransactionId: id,
    });
    if (!existing) {
      return { error: "Movimiento no encontrado", status: 404 };
    }

    const existingPrimitives = existing.toPrimitives();
    const merged: DebtTransactionPrimitives = {
      ...existingPrimitives,
      ...payload,
      id: existingPrimitives.id ?? existingPrimitives.debtTransactionId,
      debtTransactionId: existingPrimitives.debtTransactionId,
      userId: existingPrimitives.userId,
      date: payload.date ? new Date(payload.date) : existingPrimitives.date,
      updatedAt: new Date(),
    };

    const error = await this.validatePayload(userId, merged, true);
    if (error) return { error };

    await this.debtTransactions.upsert(DebtTransaction.fromPrimitives(merged));
    const updated = await this.debtTransactions.one({
      userId,
      debtTransactionId: id,
    });
    if (!updated) {
      return { error: "Movimiento no encontrado", status: 404 };
    }
    return { debtTransaction: updated.toPrimitives() };
  }

  async remove(userId: string, id: string) {
    const deleted = await this.debtTransactions.delete(userId, id);
    if (!deleted) {
      return { error: "Movimiento no encontrado", status: 404 };
    }
    return { ok: true };
  }

  private async validatePayload(
    userId: string,
    payload: DebtTransactionCreatePayload | DebtTransactionPrimitives,
    isUpdate: boolean
  ): Promise<string | null> {
    if (!isUpdate && !payload.debtId) {
      return "Falta la deuda";
    }

    if (payload.debtId) {
      const debt = await this.debts.one({ userId, debtId: payload.debtId });
      if (!debt) return "Deuda no encontrada";
    }

    if (payload.accountId) {
      const account = await this.accounts.one({
        userId,
        accountId: payload.accountId,
      });
      if (!account) return "Cuenta no encontrada";
    }

    return null;
  }
}

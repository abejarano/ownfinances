import type { DebtTransactionPrimitives } from "../models/debt_transaction";
import { DebtTransaction, DebtTransactionType } from "../models/debt_transaction";
import type { DebtMongoRepository } from "../repositories/debt_repository";
import type { DebtTransactionMongoRepository } from "../repositories/debt_transaction_repository";
import type { AccountMongoRepository } from "../repositories/account_repository";
import type { TransactionMongoRepository } from "../repositories/transaction_repository";
import type { CategoryMongoRepository } from "../repositories/category_repository";
import { Transaction, TransactionType, TransactionStatus } from "../models/transaction";
import type {
  DebtTransactionCreatePayload,
  DebtTransactionUpdatePayload,
} from "../http/validation/debt_transactions.validation";

export class DebtTransactionsService {
  constructor(
    private readonly debtTransactions: DebtTransactionMongoRepository,
    private readonly debts: DebtMongoRepository,
    private readonly accounts: AccountMongoRepository,
    private readonly transactions: TransactionMongoRepository,
    private readonly categories: CategoryMongoRepository
  ) {}

  async create(userId: string, payload: DebtTransactionCreatePayload) {
    const error = await this.validatePayload(userId, payload, false);
    if (error) return { error };

    const date = payload.date ? new Date(payload.date) : new Date();

    // Obtener la deuda para obtener la moneda
    const debt = await this.debts.one({ userId, debtId: payload.debtId! });
    if (!debt) {
      return { error: "Deuda no encontrada" };
    }
    const debtPrimitives = debt.toPrimitives();
    const currency = debtPrimitives.currency;

    const tx = DebtTransaction.create({
      userId,
      debtId: payload.debtId!,
      date,
      type: payload.type!,
      amount: payload.amount!,
      accountId: payload.accountId ?? undefined,
      categoryId: payload.categoryId ?? null,
      note: payload.note ?? null,
    });

    await this.debtTransactions.upsert(tx);

    // Crear transacción relacionada según el tipo
    if (payload.type === DebtTransactionType.Charge) {
      if (debtPrimitives.type === "credit_card") {
         // Compra con TC: Gasto desde la cuenta vinculada
         if (!debtPrimitives.linkedAccountId) {
            return { error: "Este cartão precisa estar vinculado a uma conta do tipo Cartão." };
         }
         if (!payload.categoryId) {
            return { error: "Falta escolher uma categoria" };
         }

         const transaction = Transaction.create({
            userId,
            type: TransactionType.Expense,
            date,
            amount: payload.amount!,
            currency,
            categoryId: payload.categoryId,
            fromAccountId: debtPrimitives.linkedAccountId, // Sale del la cuenta tarjeta
            toAccountId: null,
            note: payload.note ?? `Compra em ${debtPrimitives.name}`,
            status: TransactionStatus.Cleared, // Default cleared
         });
         await this.transactions.upsert(transaction);
      } else {
        // Charge for Loan/Other (increase principal? fee?)
        // Maintain existing behavior but ensure category if needed?
        // Current logic required category for Charge.
        if (payload.categoryId) {
           const transaction = Transaction.create({
              userId,
              type: TransactionType.Expense,
              date,
              amount: payload.amount!,
              currency,
              categoryId: payload.categoryId,
              fromAccountId: null, // Unknown source for abstract debt charge
              toAccountId: null,
              note: payload.note ?? `Compra em ${debtPrimitives.name}`,
              status: TransactionStatus.Cleared,
           });
           await this.transactions.upsert(transaction);
        }
      }
    } else if (payload.type === DebtTransactionType.Payment && payload.accountId) {
      if (debtPrimitives.type === "credit_card") {
        // Pago de tarjeta es una Transferencia
        if (!debtPrimitives.linkedAccountId) {
          // Esto no debería pasar si la validación funciona, pero por seguridad:
          return { error: "Este cartão precisa estar vinculado a uma conta do tipo Cartão." };
        }
        const transaction = Transaction.create({
          userId,
          type: TransactionType.Transfer,
          date,
          amount: payload.amount!,
          currency,
          categoryId: null,
          fromAccountId: payload.accountId,
          toAccountId: debtPrimitives.linkedAccountId,
          note: payload.note ?? `Pagamento do cartão ${debtPrimitives.name}`,
          status: TransactionStatus.Cleared,
        });
        await this.transactions.upsert(transaction);
      } else {
        // Pago de préstamo es un Gasto
        if (!payload.categoryId) {
           return { error: "Falta escolher uma categoria" };
        }
        const transaction = Transaction.create({
          userId,
          type: TransactionType.Expense,
          date,
          amount: payload.amount!,
          currency,
          categoryId: payload.categoryId, 
          fromAccountId: payload.accountId,
          toAccountId: null,
          note: payload.note ?? `Parcela do empréstimo ${debtPrimitives.name}`,
          status: TransactionStatus.Cleared,
        });
        await this.transactions.upsert(transaction);
      }
    }

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
      categoryId: payload.categoryId !== undefined ? payload.categoryId : existingPrimitives.categoryId,
      accountId: payload.accountId !== undefined ? (payload.accountId ?? undefined) : existingPrimitives.accountId,
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

    // Validar categoría cuando es charge
    if (payload.type === DebtTransactionType.Charge) {
      if (!payload.categoryId) {
        return "Falta la categoria para la compra";
      }
      const category = await this.categories.one({
        userId,
        categoryId: payload.categoryId,
      });
      if (!category) return "Categoria no encontrada";
    }

    if (payload.type === DebtTransactionType.Payment) {
      const debt = await this.debts.one({ userId, debtId: payload.debtId! });
      if (debt) {
        const primitives = debt.toPrimitives();
        if (primitives.type === "credit_card") {
          if (!primitives.linkedAccountId) {
            return "Este cartão precisa estar vinculado a uma conta do tipo Cartão.";
          }
        } else {
          // Loan / Other
          if (!payload.categoryId) {
            return "Falta escolher uma categoria";
          }
        }
      }
    }

    return null;
  }
}

import type { Paginate } from "@abejarano/ts-mongodb-criteria"
import type { Result } from "../bootstrap/response"
import { buildDebtTransactionsCriteria } from "../http/criteria/debt_transactions.criteria"
import type {
  DebtTransactionCreatePayload,
  DebtTransactionUpdatePayload,
} from "../http/validation/debt_transactions.validation"
import type { DebtTransactionPrimitives } from "../models/debt_transaction"
import {
  DebtTransaction,
  DebtTransactionType,
} from "../models/debt_transaction"
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from "../models/transaction"
import type { AccountMongoRepository } from "../repositories/account_repository"
import type { CategoryMongoRepository } from "../repositories/category_repository"
import type { DebtMongoRepository } from "../repositories/debt_repository"
import type { DebtTransactionMongoRepository } from "../repositories/debt_transaction_repository"
import type { TransactionMongoRepository } from "../repositories/transaction_repository"

export class DebtTransactionsService {
  constructor(
    private readonly debtTransactions: DebtTransactionMongoRepository,
    private readonly debts: DebtMongoRepository,
    private readonly accounts: AccountMongoRepository,
    private readonly transactions: TransactionMongoRepository,
    private readonly categories: CategoryMongoRepository
  ) {}

  async create(
    userId: string,
    payload: DebtTransactionCreatePayload
  ): Promise<Result<{ debtTransaction: DebtTransactionPrimitives }>> {
    const date = payload.date ? new Date(payload.date) : new Date()

    // Obtener la deuda para obtener la moneda
    const debt = await this.debts.one({ userId, debtId: payload.debtId! })
    if (!debt) {
      return { error: "Deuda no encontrada", status: 404 }
    }

    const debtPrimitives = debt.toPrimitives()
    const currency = debtPrimitives.currency

    const tx = DebtTransaction.create({
      userId,
      debtId: payload.debtId!,
      date,
      type: payload.type!,
      amount: payload.amount!,
      accountId: payload.accountId ?? undefined,
      categoryId: payload.categoryId ?? null,
      note: payload.note ?? null,
    })

    await this.debtTransactions.upsert(tx)

    // Crear transacción relacionada según el tipo
    if (payload.type === DebtTransactionType.Charge) {
      if (debtPrimitives.type === "credit_card") {
        // Compra con TC: Gasto desde la cuenta vinculada
        if (!debtPrimitives.linkedAccountId) {
          return {
            error:
              "Este cartão precisa estar vinculado a uma conta do tipo Cartão.",
            status: 400,
          }
        }
        if (!payload.categoryId) {
          return { error: "Falta escolher uma categoria", status: 400 }
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
        })
        await this.transactions.upsert(transaction)
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
          })
          await this.transactions.upsert(transaction)
        }
      }
    } else if (
      payload.type === DebtTransactionType.Payment &&
      payload.accountId
    ) {
      if (debtPrimitives.type === "credit_card") {
        // Pago de tarjeta es una Transferencia
        if (!debtPrimitives.linkedAccountId) {
          // Esto no debería pasar si la validación funciona, pero por seguridad:
          return {
            error:
              "Este cartão precisa estar vinculado a uma conta do tipo Cartão.",
            status: 400,
          }
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
        })
        await this.transactions.upsert(transaction)
      } else {
        // Pago de préstamo es un Gasto
        if (!payload.categoryId) {
          return { error: "Falta escolher uma categoria", status: 400 }
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
        })
        await this.transactions.upsert(transaction)
      }
    }

    return { value: { debtTransaction: tx.toPrimitives() }, status: 201 }
  }

  async update(
    userId: string,
    id: string,
    payload: DebtTransactionUpdatePayload
  ): Promise<Result<{ debtTransaction: DebtTransactionPrimitives }>> {
    const existing = await this.debtTransactions.one({
      userId,
      debtTransactionId: id,
    })
    if (!existing) {
      return { error: "Movimiento no encontrado", status: 404 }
    }

    const existingPrimitives = existing.toPrimitives()
    const merged: DebtTransactionPrimitives = {
      ...existingPrimitives,
      ...payload,
      id: existingPrimitives.id ?? existingPrimitives.debtTransactionId,
      debtTransactionId: existingPrimitives.debtTransactionId,
      userId: existingPrimitives.userId,
      date: payload.date ? new Date(payload.date) : existingPrimitives.date,
      categoryId:
        payload.categoryId !== undefined
          ? payload.categoryId
          : existingPrimitives.categoryId,
      accountId:
        payload.accountId !== undefined
          ? (payload.accountId ?? undefined)
          : existingPrimitives.accountId,
      updatedAt: new Date(),
    }

    const error = await this.validatePayload(userId, merged, true)
    if (error.error) return { error: error.error, status: error.status }

    await this.debtTransactions.upsert(DebtTransaction.fromPrimitives(merged))
    const updated = await this.debtTransactions.one({
      userId,
      debtTransactionId: id,
    })
    if (!updated) {
      return { error: "Movimiento no encontrado", status: 404 }
    }

    return { value: { debtTransaction: updated.toPrimitives() }, status: 200 }
  }

  async remove(userId: string, id: string): Promise<Result<{ ok: boolean }>> {
    const deleted = await this.debtTransactions.delete(userId, id)
    if (!deleted) {
      return { error: "Movimiento no encontrado", status: 404 }
    }
    return { value: { ok: true }, status: 200 }
  }

  private async validatePayload(
    userId: string,
    payload: DebtTransactionCreatePayload | DebtTransactionPrimitives,
    isUpdate: boolean
  ): Promise<Result<void>> {
    if (!isUpdate && !payload.debtId) {
      return { error: "Falta la deuda", status: 400 }
    }

    if (payload.debtId) {
      const debt = await this.debts.one({ userId, debtId: payload.debtId })
      if (!debt) return { error: "Deuda no encontrada", status: 400 }
    }

    if (payload.accountId) {
      const account = await this.accounts.one({
        userId,
        accountId: payload.accountId,
      })
      if (!account) return { error: "Cuenta no encontrada", status: 400 }
    }

    // Validar categoría cuando es charge
    if (payload.type === DebtTransactionType.Charge) {
      if (!payload.categoryId) {
        return { error: "Falta la categoria para la compra", status: 400 }
      }
      const category = await this.categories.one({
        userId,
        categoryId: payload.categoryId,
      })
      if (!category) return { error: "Categoria no encontrada", status: 400 }
    }

    if (payload.type === DebtTransactionType.Payment) {
      const debt = await this.debts.one({ userId, debtId: payload.debtId! })
      if (debt) {
        const primitives = debt.toPrimitives()
        if (primitives.type === "credit_card") {
          if (!primitives.linkedAccountId) {
            return {
              error:
                "Este cartão precisa estar vinculado a uma conta do tipo Cartão.",
              status: 400,
            }
          }
        } else {
          // Loan / Other
          if (!payload.categoryId) {
            return { error: "Falta escolher uma categoria", status: 400 }
          }
        }
      }
    }

    return { value: undefined, status: 200 }
  }
}

import type { Result } from "../bootstrap/response"
import type {
  TransactionCreatePayload,
  TransactionUpdatePayload,
} from "../http/validation/transactions.validation"

import type { TransactionPrimitives } from "../models/transaction"
import {
  Transaction,
  TransactionStatus,
  TransactionType,
} from "../models/transaction"
import type { AccountMongoRepository } from "../repositories/account_repository"
import type { TransactionMongoRepository } from "../repositories/transaction_repository"

export class TransactionsService {
  constructor(
    private readonly transactions: TransactionMongoRepository,
    private readonly accounts: AccountMongoRepository
  ) {}

  async create(
    userId: string,
    payload: TransactionCreatePayload
  ): Promise<Result<TransactionPrimitives>> {
    const error = await this.validatePayload(userId, payload, false)
    if (error) return { error, status: 400 }

    const date = payload.date ? new Date(payload.date) : new Date()
    const currency =
      payload.currency ?? (await this.resolveCurrency(userId, payload)) ?? "BRL"
    const status = payload.status ?? TransactionStatus.Pending

    const transaction = Transaction.create({
      userId,
      type: payload.type!,
      date,
      amount: payload.amount!,
      currency,
      categoryId: payload.categoryId ?? null,
      fromAccountId: payload.fromAccountId ?? null,
      toAccountId: payload.toAccountId ?? null,
      note: payload.note ?? null,
      tags: payload.tags ?? null,
      status,
      clearedAt: status === TransactionStatus.Cleared ? new Date() : null,
    })

    await this.transactions.upsert(transaction)
    return { value: transaction.toPrimitives(), status: 201 }
  }

  async update(
    userId: string,
    id: string,
    payload: TransactionUpdatePayload
  ): Promise<Result<TransactionPrimitives>> {
    const existing = await this.transactions.one({ userId, transactionId: id })
    if (!existing || existing.toPrimitives().deletedAt) {
      return { error: "Transacao nao encontrada", status: 404 }
    }

    const existingPrimitives = existing.toPrimitives()
    const merged: TransactionPrimitives = {
      ...existingPrimitives,
      ...payload,
      id: existingPrimitives.id ?? existingPrimitives.transactionId,
      transactionId: existingPrimitives.transactionId,
      userId: existingPrimitives.userId,
      date: payload.date ? new Date(payload.date) : existingPrimitives.date,
      updatedAt: new Date(),
    }

    const error = await this.validatePayload(userId, merged, true)
    if (error) return { error, status: 400 }

    if (merged.status === TransactionStatus.Cleared && !merged.clearedAt) {
      merged.clearedAt = new Date()
    }
    if (merged.status === TransactionStatus.Pending) {
      merged.clearedAt = null
    }

    await this.transactions.upsert(Transaction.fromPrimitives(merged))
    const updated = await this.transactions.one({ userId, transactionId: id })
    if (!updated) {
      return { error: "Transacao nao encontrada", status: 404 }
    }
    return { value: updated.toPrimitives(), status: 200 }
  }

  async clear(
    userId: string,
    id: string
  ): Promise<Result<TransactionPrimitives>> {
    const existing = await this.transactions.one({ userId, transactionId: id })
    if (!existing || existing.toPrimitives().deletedAt) {
      return { error: "Transacao nao encontrada", status: 404 }
    }

    const existingPrimitives = existing.toPrimitives()
    const cleared = Transaction.fromPrimitives({
      ...existingPrimitives,
      id: existingPrimitives.id ?? existingPrimitives.transactionId,
      status: TransactionStatus.Cleared,
      clearedAt: new Date(),
      updatedAt: new Date(),
    })

    await this.transactions.upsert(cleared)
    const updated = await this.transactions.one({ userId, transactionId: id })
    if (!updated) {
      return { error: "Transacao nao encontrada", status: 404 }
    }
    return { value: updated.toPrimitives(), status: 200 }
  }

  async remove(userId: string, id: string): Promise<Result<{ ok: true }>> {
    const existing = await this.transactions.one({ userId, transactionId: id })
    if (!existing || existing.toPrimitives().deletedAt) {
      return { error: "Transacao nao encontrada", status: 404 }
    }
    const deleted = await this.transactions.delete(userId, id)
    if (!deleted) {
      return { error: "Transacao nao encontrada", status: 404 }
    }
    return { value: { ok: true }, status: 200 }
  }

  async restore(
    userId: string,
    id: string
  ): Promise<Result<TransactionPrimitives>> {
    const restored = await this.transactions.restore(userId, id)
    if (!restored) {
      return { error: "Transacao nao encontrada", status: 404 }
    }
    const updated = await this.transactions.one({ userId, transactionId: id })
    if (!updated) {
      return { error: "Transacao nao encontrada", status: 404 }
    }
    return { value: updated.toPrimitives(), status: 200 }
  }

  private async validatePayload(
    userId: string,
    payload: TransactionCreatePayload | TransactionPrimitives,
    isUpdate: boolean
  ): Promise<string | null> {
    const type = payload.type
    if (type === TransactionType.Income) {
      if (!payload.categoryId) return "Escolha uma categoria"
      if (!payload.toAccountId) return "Escolha uma conta"
    }
    if (type === TransactionType.Expense) {
      if (!payload.categoryId) return "Escolha uma categoria"
      if (!payload.fromAccountId) return "Escolha uma conta"
    }
    if (type === TransactionType.Transfer) {
      if (!payload.fromAccountId || !payload.toAccountId) {
        return "Escolha uma conta"
      }
      if (payload.categoryId) {
        return "Transferencias nao tem categoria"
      }
    }

    if (payload.fromAccountId) {
      const account = await this.accounts.one({
        userId,
        accountId: payload.fromAccountId,
      })
      if (!account) {
        return "Conta de origem nao encontrada"
      }
    }
    if (payload.toAccountId) {
      const account = await this.accounts.one({
        userId,
        accountId: payload.toAccountId,
      })
      if (!account) {
        return "Conta de destino nao encontrada"
      }
    }

    return null
  }

  private async resolveCurrency(
    userId: string,
    payload: Partial<TransactionCreatePayload | TransactionUpdatePayload>
  ) {
    if (payload.type === TransactionType.Income && payload.toAccountId) {
      const account = await this.accounts.one({
        userId,
        accountId: payload.toAccountId,
      })
      return account?.toPrimitives().currency
    }
    if (payload.type === TransactionType.Expense && payload.fromAccountId) {
      const account = await this.accounts.one({
        userId,
        accountId: payload.fromAccountId,
      })
      return account?.toPrimitives().currency
    }
    if (payload.type === TransactionType.Transfer && payload.fromAccountId) {
      const account = await this.accounts.one({
        userId,
        accountId: payload.fromAccountId,
      })
      return account?.toPrimitives().currency
    }
    return undefined
  }
}

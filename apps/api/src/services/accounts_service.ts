import type {
  AccountMongoRepository,
  AccountPrimitives,
  TransactionMongoRepository,
} from "@desquadra/database"
import { Account } from "@desquadra/database"
import type { Result } from "../bootstrap/response"
import type {
  AccountCreatePayload,
  AccountUpdatePayload,
} from "../http/validation/accounts.validation"

export class AccountsService {
  constructor(
    private readonly accounts: AccountMongoRepository,
    private readonly transactions: TransactionMongoRepository
  ) {}

  async create(userId: string, payload: AccountCreatePayload) {
    const account = Account.create({
      userId: userId,
      name: payload.name!,
      type: payload.type!,
      bankType: payload.bankType ?? null,
      currency: payload.currency ?? "BRL",
      isActive: payload.isActive ?? true,
    })

    await this.accounts.upsert(account)
    return { account: account.toPrimitives() }
  }

  async update(
    userId: string,
    accountId: string,
    payload: AccountUpdatePayload
  ): Promise<Result<AccountPrimitives>> {
    const existing = await this.accounts.one({
      userId,
      accountId,
    })
    if (!existing) {
      return { error: "Cuenta no encontrada", status: 404 }
    }

    const existingPrimitives = existing.toPrimitives()
    const merged: AccountPrimitives = {
      ...existingPrimitives,
      ...payload,
      id: existingPrimitives.id ?? existingPrimitives.accountId,
      accountId: existingPrimitives.accountId,
      userId: existingPrimitives.userId,
      updatedAt: new Date(),
    }

    const account = Account.fromPrimitives(merged)

    await this.accounts.upsert(account)

    return { value: account.toPrimitives(), status: 200 }
  }

  async remove(
    userId: string,
    accountId: string
  ): Promise<Result<{ ok: boolean }>> {
    const existing = await this.accounts.one({ userId, accountId })
    if (!existing) {
      return { error: "Cuenta no encontrada", status: 404 }
    }

    await this.transactions.deleteManyByAccount(userId, accountId)

    const deleted = await this.accounts.delete(userId, accountId)
    if (!deleted) {
      return { error: "Cuenta no encontrada", status: 404 }
    }

    return { value: { ok: true }, status: 200 }
  }
}

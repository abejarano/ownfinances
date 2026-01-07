import type { AccountPrimitives } from "../models/account";
import { Account } from "../models/account";
import type { AccountMongoRepository } from "../repositories/account_repository";
import type {
  AccountCreatePayload,
  AccountUpdatePayload,
} from "../http/validation/accounts.validation";

export class AccountsService {
  constructor(private readonly accounts: AccountMongoRepository) {}

  async create(userId: string, payload: AccountCreatePayload) {
    const account = Account.create({
      userId,
      name: payload.name!,
      type: payload.type!,
      currency: payload.currency ?? "BRL",
      isActive: payload.isActive ?? true,
    });

    await this.accounts.upsert(account);
    return { account: account.toPrimitives() };
  }

  async update(
    userId: string,
    accountId: string,
    payload: AccountUpdatePayload
  ) {
    const existing = await this.accounts.one({
      userId,
      accountId,
    });
    if (!existing) {
      return { error: "Cuenta no encontrada", status: 404 };
    }

    const existingPrimitives = existing.toPrimitives();
    const merged: AccountPrimitives = {
      ...existingPrimitives,
      ...payload,
      id: existingPrimitives.id ?? existingPrimitives.accountId,
      accountId: existingPrimitives.accountId,
      userId: existingPrimitives.userId,
      updatedAt: new Date(),
    };

    const account = Account.fromPrimitives(merged);
    await this.accounts.upsert(account);
    return { account: account.toPrimitives() };
  }

  async remove(userId: string, accountId: string) {
    const deleted = await this.accounts.delete(userId, accountId);
    if (!deleted) {
      return { error: "Cuenta no encontrada", status: 404 };
    }
    return { ok: true };
  }
}

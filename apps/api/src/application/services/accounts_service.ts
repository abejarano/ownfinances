import type { AccountPrimitives, AccountType } from "../../domain/account";
import { Account } from "../../domain/account";
import type { AccountMongoRepository } from "../../repositories/account_repository";
import { ObjectId } from "mongodb";

export class AccountsService {
  constructor(private readonly accounts: AccountMongoRepository) {}

  async create(userId: string, payload: Partial<AccountPrimitives>) {
    const error = this.validate(payload, false);
    if (error) return { error };

    const now = new Date();
    const newId = new ObjectId().toHexString();
    const account = new Account({
      id: newId,
      accountId: newId,
      userId,
      name: payload.name!,
      type: payload.type!,
      currency: payload.currency ?? "BRL",
      isActive: payload.isActive ?? true,
      createdAt: now,
      updatedAt: now,
    });

    await this.accounts.upsert(account);
    return { account: account.toPrimitives() };
  }

  async update(userId: string, accountId: string, payload: Partial<AccountPrimitives>) {
    const existing = await this.accounts.one({
      userId,
      accountId,
    });
    if (!existing) {
      return { error: "Cuenta no encontrada", status: 404 };
    }

    const merged: AccountPrimitives = {
      ...existing,
      ...payload,
      id: existing.id ?? existing.accountId,
      accountId: existing.accountId,
      userId: existing.userId,
      updatedAt: new Date(),
    };

    const error = this.validate(merged, true);
    if (error) return { error };

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

  private validate(
    payload: Partial<AccountPrimitives>,
    isUpdate: boolean,
  ): string | null {
    if (!isUpdate && !payload.name) {
      return "Falta el nombre de la cuenta";
    }
    if (payload.type && !isAccountType(payload.type)) {
      return "Tipo de cuenta invalido";
    }
    if (!isUpdate && !payload.type) {
      return "Tipo de cuenta invalido";
    }
    return null;
  }
}

function isAccountType(value: string): value is AccountType {
  return (
    value === "cash" ||
    value === "bank" ||
    value === "wallet" ||
    value === "broker" ||
    value === "credit_card"
  );
}

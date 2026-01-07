import type { AccountMongoRepository } from "../../repositories/account_repository";
import { Account } from "../../models/account";
import type { AccountPrimitives } from "../../models/account";
import type { AccountsService } from "../../services/accounts_service";
import { buildAccountsCriteria } from "../criteria/accounts.criteria";
import { badRequest, notFound } from "../errors";
import type {
  AccountCreatePayload,
  AccountUpdatePayload,
} from "../validation/accounts.validation";

export class AccountsController {
  constructor(
    private readonly repo: AccountMongoRepository,
    private readonly service: AccountsService
  ) {}

  async list({
    query,
    userId,
  }: {
    query: Record<string, string | undefined>;
    userId?: string;
  }) {
    const criteria = buildAccountsCriteria(query, userId ?? "");
    const result = await this.repo.list<AccountPrimitives>(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Account.fromPrimitives(item).toPrimitives()
      ),
    };
  }

  async create({
    body,
    set,
    userId,
  }: {
    body: AccountCreatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { account } = await this.service.create(userId ?? "", body);
    return account!;
  }

  async getById({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const account = await this.repo.one({
      userId: userId ?? "",
      accountId: params.id,
    });
    if (!account) return notFound(set, "Cuenta no encontrada");
    return account.toPrimitives();
  }

  async update({
    params,
    body,
    set,
    userId,
  }: {
    params: { id: string };
    body: AccountUpdatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { account, error, status } = await this.service.update(
      userId ?? "",
      params.id,
      body
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return account!;
  }

  async remove({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const { ok, error, status } = await this.service.remove(
      userId ?? "",
      params.id
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return { ok: ok === true };
  }
}

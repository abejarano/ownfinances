import type { AccountMongoRepository } from "../../repositories/account_repository";
import { Account } from "../../domain/account";
import type { AccountsService } from "../../application/services/accounts_service";
import { buildAccountsCriteria } from "../criteria/accounts.criteria";
import { badRequest, notFound } from "../errors";

export class AccountsController {
  constructor(
    private readonly repo: AccountMongoRepository,
    private readonly service: AccountsService,
    private readonly userId: string,
  ) {}

  list = async ({ query }: { query: Record<string, string | undefined> }) => {
    const criteria = buildAccountsCriteria(query, this.userId);
    const result = await this.repo.list(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Account.fromPrimitives(item).toPrimitives(),
      ),
    };
  };

  create = async ({ body, set }: { body: unknown; set: { status: number } }) => {
    const { account, error } = await this.service.create(
      body as Record<string, unknown>,
    );
    if (error) return badRequest(set, error);
    return account!;
  };

  getById = async ({ params, set }: { params: { id: string }; set: { status: number } }) => {
    const account = await this.repo.one({ userId: this.userId, accountId: params.id });
    if (!account) return notFound(set, "Cuenta no encontrada");
    return Account.fromPrimitives(account).toPrimitives();
  };

  update = async ({ params, body, set }: { params: { id: string }; body: unknown; set: { status: number } }) => {
    const { account, error, status } = await this.service.update(
      params.id,
      body as Record<string, unknown>,
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return account!;
  };

  remove = async ({ params, set }: { params: { id: string }; set: { status: number } }) => {
    const { ok, error, status } = await this.service.remove(params.id);
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return { ok: ok === true };
  };
}

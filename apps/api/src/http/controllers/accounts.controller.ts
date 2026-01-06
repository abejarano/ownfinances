import type { AccountMongoRepository } from "../../repositories/account_repository";
import { Account } from "../../domain/account";
import type { AccountsService } from "../../application/services/accounts_service";
import { buildAccountsCriteria } from "../criteria/accounts.criteria";
import { badRequest, notFound } from "../errors";

export class AccountsController {
  constructor(
    private readonly repo: AccountMongoRepository,
    private readonly service: AccountsService,
  ) {}

  list = async ({ query, userId }: { query: Record<string, string | undefined>; userId?: string }) => {
    const criteria = buildAccountsCriteria(query, userId ?? "");
    const result = await this.repo.list(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Account.fromPrimitives(item).toPrimitives(),
      ),
    };
  };

  create = async ({ body, set, userId }: { body: unknown; set: { status: number }; userId?: string }) => {
    const { account, error } = await this.service.create(
      userId ?? "",
      body as Record<string, unknown>,
    );
    if (error) return badRequest(set, error);
    return account!;
  };

  getById = async ({ params, set, userId }: { params: { id: string }; set: { status: number }; userId?: string }) => {
    const account = await this.repo.one({ userId: userId ?? "", accountId: params.id });
    if (!account) return notFound(set, "Cuenta no encontrada");
    return Account.fromPrimitives(account).toPrimitives();
  };

  update = async ({ params, body, set, userId }: { params: { id: string }; body: unknown; set: { status: number }; userId?: string }) => {
    const { account, error, status } = await this.service.update(
      userId ?? "",
      params.id,
      body as Record<string, unknown>,
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return account!;
  };

  remove = async ({ params, set, userId }: { params: { id: string }; set: { status: number }; userId?: string }) => {
    const { ok, error, status } = await this.service.remove(userId ?? "", params.id);
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return { ok: ok === true };
  };
}

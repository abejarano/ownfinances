import type { Criteria, Paginate } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { Account, AccountPrimitives } from "../domain/account";

export class AccountMongoRepository extends MongoRepository<Account> {
  private static instance: AccountMongoRepository | null = null;

  private constructor() {
    super();
  }

  static getInstance(): AccountMongoRepository {
    if (!AccountMongoRepository.instance) {
      AccountMongoRepository.instance = new AccountMongoRepository();
    }
    return AccountMongoRepository.instance;
  }

  collectionName(): string {
    return "accounts";
  }

  async upsert(account: Account): Promise<void> {
    await this.persist(account.getId(), account);
  }

  async delete(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({ userId, accountId: id });
    return result.deletedCount > 0;
  }

  async one(filter: object): Promise<AccountPrimitives | null> {
    const collection = await this.collection();
    const doc = await collection.findOne(filter);
    return doc ? (doc as unknown as AccountPrimitives) : null;
  }

  async list(criteria: Criteria): Promise<Paginate<AccountPrimitives>> {
    const documents = await this.searchByCriteria<AccountPrimitives>(criteria);
    const pagination = await this.paginate(documents);
    return {
      ...pagination,
      results: pagination.results,
    };
  }
}

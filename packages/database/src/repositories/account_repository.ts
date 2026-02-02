import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { Collection } from "mongodb";
import { Account, AccountPrimitives } from "../models/account";

export class AccountMongoRepository
  extends MongoRepository<Account>
  implements IRepository<Account>
{
  private static instance: AccountMongoRepository | null = null;

  private constructor() {
    super(Account);
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

  async search(filter: object): Promise<AccountPrimitives[]> {
    const collection = await this.collection();
    const results = await collection.find(filter).toArray();
    return results.map((doc) => {
      const { _id, ...rest } = doc as Record<string, any>;
      return rest as AccountPrimitives;
    });
  }

  async delete(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({ userId, accountId: id });
    return result.deletedCount > 0;
  }

  protected async ensureIndexes(collection: Collection): Promise<void> {}
}

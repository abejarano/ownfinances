import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { Debt } from "../models/debt";

export class DebtMongoRepository
  extends MongoRepository<Debt>
  implements IRepository<Debt>
{
  private static instance: DebtMongoRepository | null = null;
  private constructor() {
    super(Debt);
  }

  static getInstance(): DebtMongoRepository {
    if (!DebtMongoRepository.instance) {
      DebtMongoRepository.instance = new DebtMongoRepository();
    }
    return DebtMongoRepository.instance;
  }

  collectionName(): string {
    return "debts";
  }

  async delete(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({ userId, debtId: id });
    return result.deletedCount > 0;
  }
}

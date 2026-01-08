import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { Budget } from "../models/budget";
import { Collection } from "mongodb";

export class BudgetMongoRepository
  extends MongoRepository<Budget>
  implements IRepository<Budget>
{
  protected async ensureIndexes(collection: Collection): Promise<void> {}
  private static instance: BudgetMongoRepository | null = null;

  private constructor() {
    super(Budget);
  }

  static getInstance(): BudgetMongoRepository {
    if (!BudgetMongoRepository.instance) {
      BudgetMongoRepository.instance = new BudgetMongoRepository();
    }
    return BudgetMongoRepository.instance;
  }

  collectionName(): string {
    return "budgets";
  }

  async delete(userId: string, budgetId: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({ userId, budgetId });
    return result.deletedCount > 0;
  }
}

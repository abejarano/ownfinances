import type { Criteria, Paginate } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { Budget, BudgetPrimitives } from "../domain/budget";

export class BudgetMongoRepository extends MongoRepository<Budget> {
  private static instance: BudgetMongoRepository | null = null;

  private constructor() {
    super();
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

  async upsert(budget: Budget): Promise<void> {
    await this.persist(budget.getId(), budget);
  }

  async one(filter: object): Promise<BudgetPrimitives | null> {
    const collection = await this.collection();
    const doc = await collection.findOne(filter);
    return doc ? (doc as unknown as BudgetPrimitives) : null;
  }

  async delete(userId: string, budgetId: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({ userId, budgetId });
    return result.deletedCount > 0;
  }

  async list(criteria: Criteria): Promise<Paginate<BudgetPrimitives>> {
    const documents = await this.searchByCriteria<BudgetPrimitives>(criteria);
    const pagination = await this.paginate(documents);
    return {
      ...pagination,
      results: pagination.results,
    };
  }
}

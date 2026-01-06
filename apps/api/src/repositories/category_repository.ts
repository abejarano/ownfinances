import type { Criteria, Paginate } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { Category, CategoryPrimitives } from "../domain/category";

export class CategoryMongoRepository extends MongoRepository<Category> {
  private static instance: CategoryMongoRepository | null = null;

  private constructor() {
    super();
  }

  static getInstance(): CategoryMongoRepository {
    if (!CategoryMongoRepository.instance) {
      CategoryMongoRepository.instance = new CategoryMongoRepository();
    }
    return CategoryMongoRepository.instance;
  }

  collectionName(): string {
    return "categories";
  }

  async upsert(category: Category): Promise<void> {
    await this.persist(category.getId(), category);
  }

  async delete(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({ userId, categoryId: id });
    return result.deletedCount > 0;
  }

  async one(filter: object): Promise<CategoryPrimitives | null> {
    const collection = await this.collection();
    const doc = await collection.findOne(filter);
    return doc ? (doc as unknown as CategoryPrimitives) : null;
  }

  async list(criteria: Criteria): Promise<Paginate<CategoryPrimitives>> {
    const documents = await this.searchByCriteria<CategoryPrimitives>(criteria);
    const pagination = await this.paginate(documents);
    return {
      ...pagination,
      results: pagination.results,
    };
  }

  async search(criteria: Criteria): Promise<CategoryPrimitives[]> {
    return this.searchByCriteria<CategoryPrimitives>(criteria);
  }
}

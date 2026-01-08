import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { Category } from "../models/category";
import type { CategoryPrimitives } from "../models/category";
import { Collection } from "mongodb";

export class CategoryMongoRepository
  extends MongoRepository<Category>
  implements IRepository<Category>
{
  protected async ensureIndexes(collection: Collection): Promise<void> {}
  private static instance: CategoryMongoRepository | null = null;
  private constructor() {
    super(Category);
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

  async search(userId: string): Promise<CategoryPrimitives[]> {
    const collection = await this.collection();
    const results = await collection
      .find({ userId })
      .sort({ createdAt: -1 })
      .toArray();
    return results.map((doc) => {
      const { _id, ...rest } = doc as Record<string, any>;
      return rest as CategoryPrimitives;
    });
  }

  async delete(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({ userId, categoryId: id });
    return result.deletedCount > 0;
  }
}

import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { Goal } from "../models/goal";

export class GoalMongoRepository
  extends MongoRepository<Goal>
  implements IRepository<Goal>
{
  private static instance: GoalMongoRepository | null = null;
  private constructor() {
    super(Goal);
  }

  static getInstance(): GoalMongoRepository {
    if (!GoalMongoRepository.instance) {
      GoalMongoRepository.instance = new GoalMongoRepository();
    }
    return GoalMongoRepository.instance;
  }

  collectionName(): string {
    return "goals";
  }

  async delete(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({ userId, goalId: id });
    return result.deletedCount > 0;
  }
}

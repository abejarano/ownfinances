import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { GoalContribution } from "../models/goal_contribution";

export class GoalContributionMongoRepository
  extends MongoRepository<GoalContribution>
  implements IRepository<GoalContribution>
{
  private static instance: GoalContributionMongoRepository | null = null;
  private constructor() {
    super(GoalContribution);
  }

  static getInstance(): GoalContributionMongoRepository {
    if (!GoalContributionMongoRepository.instance) {
      GoalContributionMongoRepository.instance =
        new GoalContributionMongoRepository();
    }
    return GoalContributionMongoRepository.instance;
  }

  collectionName(): string {
    return "goal_contributions";
  }

  async delete(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({
      userId,
      goalContributionId: id,
    });
    return result.deletedCount > 0;
  }

  async sumByGoal(
    userId: string,
    options?: { goalId?: string; start?: Date; end?: Date }
  ): Promise<number> {
    const collection = await this.collection();
    const match: Record<string, unknown> = { userId };

    if (options?.goalId) {
      match.goalId = options.goalId;
    }

    if (options?.start && options?.end) {
      match.date = { $gte: options.start, $lte: options.end };
    } else if (options?.start) {
      match.date = { $gte: options.start };
    } else if (options?.end) {
      match.date = { $lte: options.end };
    }

    const results = await collection
      .aggregate([
        { $match: match },
        { $group: { _id: "$goalId", total: { $sum: "$amount" } } },
      ])
      .toArray();

    if (results.length == 0) return 0;
    return results[0].total as number;
  }
}

import { IRepository, MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { RecurringRule } from "../models/recurring/recurring_rule";
import type { RecurringRulePrimitives } from "../models/recurring/recurring_rule";
import { Collection } from "mongodb";

export class RecurringRuleMongoRepository
  extends MongoRepository<RecurringRule>
  implements IRepository<RecurringRule>
{
  private static instance: RecurringRuleMongoRepository;

  private constructor() {
    super(RecurringRule);
  }

  public static getInstance(): RecurringRuleMongoRepository {
    if (!this.instance) {
      this.instance = new RecurringRuleMongoRepository();
    }
    return this.instance;
  }

  collectionName(): string {
    return "recurring_rules";
  }

  async ensureIndexes(collection: Collection): Promise<void> {
    await collection.createIndex(
      { userId: 1, signature: 1 },
      {
        unique: true,
        partialFilterExpression: {
          isActive: true,
          signature: { $exists: true },
        },
      }
    );
    await collection.createIndex({ userId: 1, isActive: 1, startDate: -1 });
  }

  async searchActive(userId: string): Promise<RecurringRule[]> {
    const collection = await this.collection<RecurringRule>();
    const results = await collection
      .find({
        userId,
        isActive: true,
      })
      .sort({ startDate: -1 })
      .toArray();

    return results.map((doc) => {
      return RecurringRule.fromPrimitives({
        ...doc.toPrimitives(),
        id: doc._id.toString(),
      });
    });
  }

  async deactivateActiveDuplicatesBySignature(input: {
    userId: string;
    signature: string;
    keepRecurringRuleId: string;
  }): Promise<number> {
    const collection = await this.collection();
    const result = await collection.updateMany(
      {
        userId: input.userId,
        signature: input.signature,
        isActive: true,
        recurringRuleId: { $ne: input.keepRecurringRuleId },
      },
      { $set: { isActive: false } }
    );
    return result.modifiedCount;
  }

  async remove(recurringRuleId: string): Promise<void> {
    const collection = await this.collection();
    await collection.deleteOne({ recurringRuleId });
  }
}

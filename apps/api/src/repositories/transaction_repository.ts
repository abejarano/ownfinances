import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { Transaction, TransactionType } from "../models/transaction";

export class TransactionMongoRepository
  extends MongoRepository<Transaction>
  implements IRepository<Transaction>
{
  private static instance: TransactionMongoRepository | null = null;
  private constructor() {
    super(Transaction);
  }

  static getInstance(): TransactionMongoRepository {
    if (!TransactionMongoRepository.instance) {
      TransactionMongoRepository.instance = new TransactionMongoRepository();
    }
    return TransactionMongoRepository.instance;
  }

  collectionName(): string {
    return "transactions";
  }

  async delete(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({ userId, transactionId: id });
    return result.deletedCount > 0;
  }

  async sumByCategory(
    userId: string,
    start: Date,
    end: Date
  ): Promise<
    Array<{ categoryId: string; type: TransactionType; total: number }>
  > {
    const collection = await this.collection();
    const results = await collection
      .aggregate([
        {
          $match: {
            userId,
            type: { $in: [TransactionType.Income, TransactionType.Expense] },
            date: { $gte: start, $lte: end },
            categoryId: { $ne: null },
          },
        },
        {
          $group: {
            _id: { categoryId: "$categoryId", type: "$type" },
            total: { $sum: "$amount" },
          },
        },
        {
          $project: {
            _id: 0,
            categoryId: "$_id.categoryId",
            type: "$_id.type",
            total: 1,
          },
        },
      ])
      .toArray();

    return results as Array<{
      categoryId: string;
      type: TransactionType;
      total: number;
    }>;
  }
}

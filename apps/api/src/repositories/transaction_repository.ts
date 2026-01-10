import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { Transaction, TransactionType } from "../models/transaction";
import { Collection } from "mongodb";

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

  async ensureIndexes(collection: Collection): Promise<void> {
    await collection.createIndex(
      { userId: 1, recurringUniqueKey: 1 },
      {
        unique: true,
        partialFilterExpression: {
          recurringUniqueKey: { $exists: true },
          deletedAt: null,
        },
      }
    );
    await collection.createIndex({
      userId: 1,
      status: 1,
      recurringRuleId: 1,
    });
  }

  async delete(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.updateOne(
      { userId, transactionId: id, deletedAt: null },
      { $set: { deletedAt: new Date() } }
    );
    return result.modifiedCount > 0;
  }

  async deleteManyByCategory(
    userId: string,
    categoryId: string
  ): Promise<number> {
    const collection = await this.collection();
    const now = new Date();
    const result = await collection.updateMany(
      { userId, categoryId, deletedAt: null },
      { $set: { deletedAt: now, updatedAt: now } }
    );
    return result.modifiedCount;
  }

  async deleteManyByAccount(
    userId: string,
    accountId: string
  ): Promise<number> {
    const collection = await this.collection();
    const now = new Date();
    const result = await collection.updateMany(
      {
        userId,
        deletedAt: null,
        $or: [{ fromAccountId: accountId }, { toAccountId: accountId }],
      },
      { $set: { deletedAt: now, updatedAt: now } }
    );
    return result.modifiedCount;
  }

  async restore(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.updateOne(
      { userId, transactionId: id },
      { $set: { deletedAt: null } }
    );
    return result.modifiedCount > 0;
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
            deletedAt: null,
            status: "cleared",
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

  async sumByAccount(
    userId: string,
    start: Date,
    end: Date
  ): Promise<Array<{ accountId: string; balance: number }>> {
    const collection = await this.collection();
    const results = await collection
      .aggregate([
        {
          $match: {
            userId,
            status: "cleared",
            deletedAt: null,
            date: { $gte: start, $lte: end },
          },
        },
        {
          $project: {
            entries: {
              $concatArrays: [
                {
                  $cond: [
                    {
                      $in: [
                        "$type",
                        [TransactionType.Expense, TransactionType.Transfer],
                      ],
                    },
                    [
                      {
                        accountId: "$fromAccountId",
                        amount: { $multiply: ["$amount", -1] },
                      },
                    ],
                    [],
                  ],
                },
                {
                  $cond: [
                    {
                      $in: [
                        "$type",
                        [TransactionType.Income, TransactionType.Transfer],
                      ],
                    },
                    [{ accountId: "$toAccountId", amount: "$amount" }],
                    [],
                  ],
                },
              ],
            },
          },
        },
        { $unwind: "$entries" },
        { $match: { "entries.accountId": { $ne: null } } },
        {
          $group: {
            _id: "$entries.accountId",
            total: { $sum: "$entries.amount" },
          },
        },
        { $project: { _id: 0, accountId: "$_id", balance: "$total" } },
      ])
      .toArray();

    return results as Array<{ accountId: string; balance: number }>;
  }

  async sumByGoalTag(userId: string, goalId: string): Promise<number> {
    const collection = await this.collection();
    const results = await collection
      .aggregate([
        {
          $match: {
            userId,
            tags: { $in: [goalId] },
            type: { $in: [TransactionType.Income, TransactionType.Expense] },
          },
        },
        { $group: { _id: "$userId", total: { $sum: "$amount" } } },
      ])
      .toArray();

    if (results.length === 0) return 0;
    return results[0].total as number;
  }

  async confirmBatch(
    transactionIds: string[],
    userId: string
  ): Promise<number> {
    const collection = await this.collection();
    const now = new Date();
    const result = await collection.updateMany(
      {
        userId,
        transactionId: { $in: transactionIds },
        status: "pending",
        deletedAt: null,
      },
      {
        $set: {
          status: "cleared",
          clearedAt: now,
          updatedAt: now,
        },
      }
    );
    return result.modifiedCount;
  }
}

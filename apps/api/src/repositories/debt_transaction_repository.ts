import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import {
  DebtTransaction,
  DebtTransactionType,
} from "../models/debt_transaction";
import { Collection } from "mongodb";

export class DebtTransactionMongoRepository
  extends MongoRepository<DebtTransaction>
  implements IRepository<DebtTransaction>
{
  protected async ensureIndexes(collection: Collection): Promise<void> {}
  private static instance: DebtTransactionMongoRepository | null = null;
  private constructor() {
    super(DebtTransaction);
  }

  static getInstance(): DebtTransactionMongoRepository {
    if (!DebtTransactionMongoRepository.instance) {
      DebtTransactionMongoRepository.instance =
        new DebtTransactionMongoRepository();
    }
    return DebtTransactionMongoRepository.instance;
  }

  collectionName(): string {
    return "debt_transactions";
  }

  async delete(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({
      userId,
      debtTransactionId: id,
    });
    return result.deletedCount > 0;
  }

  async sumByDebt(
    userId: string,
    options?: {
      debtId?: string;
      start?: Date;
      end?: Date;
      types?: DebtTransactionType[];
    }
  ): Promise<
    Array<{ debtId: string; type: DebtTransactionType; total: number }>
  > {
    const collection = await this.collection();
    const match: Record<string, unknown> = { userId };

    if (options?.debtId) {
      match.debtId = options.debtId;
    }

    if (options?.start && options?.end) {
      match.date = { $gte: options.start, $lte: options.end };
    } else if (options?.start) {
      match.date = { $gte: options.start };
    } else if (options?.end) {
      match.date = { $lte: options.end };
    }

    if (options?.types && options.types.length > 0) {
      match.type = { $in: options.types };
    }

    const results = await collection
      .aggregate([
        { $match: match },
        {
          $group: {
            _id: { debtId: "$debtId", type: "$type" },
            total: { $sum: "$amount" },
          },
        },
        {
          $project: {
            _id: 0,
            debtId: "$_id.debtId",
            type: "$_id.type",
            total: 1,
          },
        },
      ])
      .toArray();

    return results as Array<{
      debtId: string;
      type: DebtTransactionType;
      total: number;
    }>;
  }
}

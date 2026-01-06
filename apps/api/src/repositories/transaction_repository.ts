import type { Criteria, Paginate } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { Transaction, TransactionPrimitives } from "../domain/transaction";

export class TransactionMongoRepository extends MongoRepository<Transaction> {
  private static instance: TransactionMongoRepository | null = null;

  private constructor() {
    super();
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

  async upsert(transaction: Transaction): Promise<void> {
    await this.persist(transaction.getId(), transaction);
  }

  async delete(userId: string, id: string): Promise<boolean> {
    const collection = await this.collection();
    const result = await collection.deleteOne({ userId, transactionId: id });
    return result.deletedCount > 0;
  }

  async one(filter: object): Promise<TransactionPrimitives | null> {
    const collection = await this.collection();
    const doc = await collection.findOne(filter);
    return doc ? (doc as unknown as TransactionPrimitives) : null;
  }

  async list(criteria: Criteria): Promise<Paginate<TransactionPrimitives>> {
    const documents = await this.searchByCriteria<TransactionPrimitives>(criteria);
    const pagination = await this.paginate(documents);
    return {
      ...pagination,
      results: pagination.results,
    };
  }
}

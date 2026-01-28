import type { IRepository } from "@abejarano/ts-mongodb-criteria"
import { MongoRepository } from "@abejarano/ts-mongodb-criteria"
import { Collection } from "mongodb"
import { Bank } from "../models/bank"

export class BankMongoRepository
  extends MongoRepository<Bank>
  implements IRepository<Bank>
{
  protected async ensureIndexes(collection: Collection): Promise<void> {
    await collection.createIndex({ country: 1 })
    await collection.createIndex({ code: 1, country: 1 }, { unique: true })
  }
  private static instance: BankMongoRepository | null = null

  private constructor() {
    super(Bank)
  }

  static getInstance(): BankMongoRepository {
    if (!BankMongoRepository.instance) {
      BankMongoRepository.instance = new BankMongoRepository()
    }
    return BankMongoRepository.instance
  }

  collectionName(): string {
    return "banks"
  }

  async banks(country?: string): Promise<Bank[]> {
    const collection = await this.collection()
    const query = country ? { country } : {}
    const banks = await collection.find(query).sort({ name: 1 }).toArray()

    return banks.map((b: any) => (b.toPrimitives ? b.toPrimitives() : b))
  }
}

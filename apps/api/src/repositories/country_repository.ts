import type { IRepository } from "@abejarano/ts-mongodb-criteria"
import { MongoRepository } from "@abejarano/ts-mongodb-criteria"
import { Collection } from "mongodb"
import { Country } from "../models/country"

export class CountryMongoRepository
  extends MongoRepository<Country>
  implements IRepository<Country>
{
  protected async ensureIndexes(collection: Collection): Promise<void> {
    await collection.createIndex({ code: 1 }, { unique: true })
    await collection.createIndex({ isActive: 1 })
  }

  private static instance: CountryMongoRepository | null = null

  private constructor() {
    super(Country)
  }

  static getInstance(): CountryMongoRepository {
    if (!CountryMongoRepository.instance) {
      CountryMongoRepository.instance = new CountryMongoRepository()
    }
    return CountryMongoRepository.instance
  }

  collectionName(): string {
    return "countries"
  }

  async countries(): Promise<Country[]> {
    const collection = await this.collection()
    const results = await collection.find({ isActive: true }).toArray()

    return results.map((c: any) => (c.toPrimitives ? c.toPrimitives() : c))
  }
}

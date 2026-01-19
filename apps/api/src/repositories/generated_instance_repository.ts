import {
  MongoRepository,
  type IRepository,
} from "@abejarano/ts-mongodb-criteria"
import { Collection } from "mongodb"
import { GeneratedInstance } from "../models/recurring/generated_instance"

export class GeneratedInstanceMongoRepository
  extends MongoRepository<GeneratedInstance>
  implements IRepository<GeneratedInstance>
{
  private static instance: GeneratedInstanceMongoRepository

  private constructor() {
    super(GeneratedInstance)
  }

  public static getInstance(): GeneratedInstanceMongoRepository {
    if (!this.instance) {
      this.instance = new GeneratedInstanceMongoRepository()
    }
    return this.instance
  }

  collectionName(): string {
    return "generated_instances"
  }

  async ensureIndexes(collection: Collection): Promise<void> {
    await collection.createIndex({ uniqueKey: 1 }, { unique: true })
    await collection.createIndex({ userId: 1, date: 1 })
  }

  async search(filters: object): Promise<GeneratedInstance[]> {
    const collection = await this.collection()
    const docs = await collection.find(filters).toArray()

    return docs.map((doc) =>
      GeneratedInstance.fromPrimitives({
        ...(doc as any),
        id: doc._id.toString(),
      })
    )
  }
  async remove(generatedInstanceId: string): Promise<void> {
    const collection = await this.collection()
    await collection.deleteOne({ generatedInstanceId })
  }
}

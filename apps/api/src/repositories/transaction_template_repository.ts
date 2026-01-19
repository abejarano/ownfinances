import {
  MongoRepository,
  type IRepository,
} from "@abejarano/ts-mongodb-criteria"
import { Collection } from "mongodb"
import { TransactionTemplate } from "../models/template/transaction_template"

export class TransactionTemplateMongoRepository
  extends MongoRepository<TransactionTemplate>
  implements IRepository<TransactionTemplate>
{
  protected async ensureIndexes(collection: Collection): Promise<void> {}
  private static instance: TransactionTemplateMongoRepository

  private constructor() {
    super(TransactionTemplate)
  }

  static getInstance(): TransactionTemplateMongoRepository {
    if (!this.instance) {
      this.instance = new TransactionTemplateMongoRepository()
    }
    return this.instance
  }

  collectionName(): string {
    return "transaction_templates"
  }

  async remove(templateId: string): Promise<void> {
    const collection = await this.collection()
    await collection.deleteOne({ templateId })
  }
}

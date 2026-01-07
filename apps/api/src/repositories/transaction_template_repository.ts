import {
  Criteria,
  IRepository,
  MongoRepository,
  Paginate,
} from "@abejarano/ts-mongodb-criteria";
import { TransactionTemplate } from "../models/template/transaction_template";

export class TransactionTemplateMongoRepository
  extends MongoRepository<TransactionTemplate>
  implements IRepository<TransactionTemplate>
{
  private static instance: TransactionTemplateMongoRepository;

  private constructor() {
    super(TransactionTemplate);
  }

  static getInstance(): TransactionTemplateMongoRepository {
    if (!this.instance) {
      this.instance = new TransactionTemplateMongoRepository();
    }
    return this.instance;
  }

  collectionName(): string {
    return "transaction_templates";
  }

  async remove(templateId: string): Promise<void> {
    const collection = await this.collection();
    await collection.deleteOne({ templateId });
  }
}

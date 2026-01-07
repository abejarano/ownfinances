import {
  Criteria,
  IRepository,
  MongoRepository,
  Paginate,
} from "@abejarano/ts-mongodb-criteria";
import { RecurringRule } from "../models/recurring/recurring_rule";

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

  async remove(recurringRuleId: string): Promise<void> {
    const collection = await this.collection();
    await collection.deleteOne({ recurringRuleId });
  }
}

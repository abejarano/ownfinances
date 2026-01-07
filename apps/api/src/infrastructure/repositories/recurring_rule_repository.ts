import { Criteria, MongoRepository, Paginate } from "@abejarano/ts-mongodb-criteria";
import { RecurringRule, RecurringRuleRepository } from "../../domain/recurring/recurring_rule";

export class RecurringRuleMongoRepository
  extends MongoRepository<RecurringRule>
  implements RecurringRuleRepository
{
  private static instance: RecurringRuleMongoRepository;

  public static getInstance(): RecurringRuleMongoRepository {
    if (!this.instance) {
      this.instance = new RecurringRuleMongoRepository();
    }
    return this.instance;
  }

  collectionName(): string {
    return "recurring_rules";
  }

  async upsert(rule: RecurringRule): Promise<void> {
    await this.persist(rule.getId(), rule);
  }

  async list(criteria: Criteria): Promise<Paginate<RecurringRule>> {
    const documents = await this.searchByCriteria<any>(criteria);
    const pagination = await this.paginate(documents);

    return {
      ...pagination,
      results: pagination.results.map((doc) =>
        RecurringRule.fromPrimitives({ ...doc, id: doc._id, ruleId: doc.ruleId } as any),
      ),
    };
  }

  async byId(ruleId: string): Promise<RecurringRule | undefined> {
    const collection = await this.collection();
    const doc = await collection.findOne({ ruleId });
    if (!doc) return undefined;
    return RecurringRule.fromPrimitives({ ...doc, id: doc._id, ruleId: (doc as any).ruleId } as any);
  }

  async remove(ruleId: string): Promise<void> {
    const collection = await this.collection();
    await collection.deleteOne({ ruleId });
  }
}

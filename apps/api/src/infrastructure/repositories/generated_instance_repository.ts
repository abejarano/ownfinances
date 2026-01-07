import { Criteria, MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { GeneratedInstance, GeneratedInstanceRepository } from "../../domain/recurring/generated_instance";

export class GeneratedInstanceMongoRepository
  extends MongoRepository<GeneratedInstance>
  implements GeneratedInstanceRepository
{
  private static instance: GeneratedInstanceMongoRepository;

  public static getInstance(): GeneratedInstanceMongoRepository {
    if (!this.instance) {
      this.instance = new GeneratedInstanceMongoRepository();
    }
    return this.instance;
  }

  collectionName(): string {
    return "generated_instances";
  }

  async upsert(instance: GeneratedInstance): Promise<void> {
    if (instance.id) {
        await this.persist(instance.id, instance);
    } else {
        // Should not happen if created via service correctly, but as fallback
        await this.persist(instance.getId(), instance);
    }
  }

  async search(criteria: Criteria): Promise<GeneratedInstance[]> {
    const docs = await this.searchByCriteria<any>(criteria);
    return docs.map((doc) =>
      GeneratedInstance.fromPrimitives({ ...doc, id: doc._id }),
    );
  }
}

import { IRepository, MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { GeneratedInstance } from "../models/recurring/generated_instance";

export class GeneratedInstanceMongoRepository
  extends MongoRepository<GeneratedInstance>
  implements IRepository<GeneratedInstance>
{
  private static instance: GeneratedInstanceMongoRepository;

  private constructor() {
    super(GeneratedInstance);
  }

  public static getInstance(): GeneratedInstanceMongoRepository {
    if (!this.instance) {
      this.instance = new GeneratedInstanceMongoRepository();
    }
    return this.instance;
  }

  collectionName(): string {
    return "generated_instances";
  }
}

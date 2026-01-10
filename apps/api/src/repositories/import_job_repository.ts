import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { ImportJob } from "../models/import_job";
import { Collection } from "mongodb";

export class ImportJobMongoRepository
  extends MongoRepository<ImportJob>
  implements IRepository<ImportJob>
{
  private static instance: ImportJobMongoRepository | null = null;

  private constructor() {
    super(ImportJob);
  }

  static getInstance(): ImportJobMongoRepository {
    if (!ImportJobMongoRepository.instance) {
      ImportJobMongoRepository.instance = new ImportJobMongoRepository();
    }
    return ImportJobMongoRepository.instance;
  }

  collectionName(): string {
    return "import_jobs";
  }

  async ensureIndexes(collection: Collection): Promise<void> {
    await collection.createIndex({ userId: 1, createdAt: -1 });
  }
}

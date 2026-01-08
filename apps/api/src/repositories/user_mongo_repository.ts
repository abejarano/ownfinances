import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { User } from "../models/auth/user";
import { Collection } from "mongodb";

export class UserMongoRepository
  extends MongoRepository<User>
  implements IRepository<User>
{
  private static instance: UserMongoRepository | null = null;

  private constructor() {
    super(User);
  }

  static getInstance(): UserMongoRepository {
    if (!UserMongoRepository.instance) {
      UserMongoRepository.instance = new UserMongoRepository();
    }
    return UserMongoRepository.instance;
  }

  collectionName(): string {
    return "users";
  }

  async ensureIndexes(collection: Collection): Promise<void> {
    await collection.createIndex({ email: 1 }, { unique: true });
  }
}

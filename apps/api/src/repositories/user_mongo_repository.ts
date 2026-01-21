import type { IRepository } from "@abejarano/ts-mongodb-criteria"
import { MongoRepository } from "@abejarano/ts-mongodb-criteria"
import { Collection } from "mongodb"
import { User } from "../models/auth/user"

export class UserMongoRepository
  extends MongoRepository<User>
  implements IRepository<User>
{
  private static instance: UserMongoRepository | null = null

  private constructor() {
    super(User)
  }

  static getInstance(): UserMongoRepository {
    if (!UserMongoRepository.instance) {
      UserMongoRepository.instance = new UserMongoRepository()
    }
    return UserMongoRepository.instance
  }

  collectionName(): string {
    return "users"
  }

  async ensureIndexes(collection: Collection): Promise<void> {
    await collection.createIndex({ email: 1 }, { unique: true })
    await collection.createIndex(
      { googleId: 1 },
      { unique: true, sparse: true }
    )
    await collection.createIndex(
      { appleId: 1 },
      { unique: true, sparse: true }
    )
  }
}

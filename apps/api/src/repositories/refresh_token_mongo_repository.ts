import type { IRepository } from "@abejarano/ts-mongodb-criteria"
import { MongoRepository } from "@abejarano/ts-mongodb-criteria"
import { Collection } from "mongodb"
import { RefreshToken } from "../models/auth/refresh_token"

export class RefreshTokenMongoRepository
  extends MongoRepository<RefreshToken>
  implements IRepository<RefreshToken>
{
  async ensureIndexes(collection: Collection): Promise<void> {
    await collection.createIndex({ tokenHash: 1 }, { unique: true })
    await collection.createIndex({ userId: 1, expiresAt: 1 })
    await collection.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 })
  }
  private static instance: RefreshTokenMongoRepository | null = null

  private constructor() {
    super(RefreshToken)
  }

  static getInstance(): RefreshTokenMongoRepository {
    if (!RefreshTokenMongoRepository.instance) {
      RefreshTokenMongoRepository.instance = new RefreshTokenMongoRepository()
    }
    return RefreshTokenMongoRepository.instance
  }

  collectionName(): string {
    return "refresh_tokens"
  }
  async pruneUserTokens(userId: string, limit: number): Promise<void> {
    const collection = await this.collection()
    // Find tokens for user, sort by newest first
    const tokens = await collection
      .find({ userId })
      .sort({ createdAt: -1 })
      .skip(limit)
      .toArray()

    if (tokens.length > 0) {
      const idsToDelete = tokens.map((t) => t._id)
      await collection.deleteMany({ _id: { $in: idsToDelete } })
    }
  }
}

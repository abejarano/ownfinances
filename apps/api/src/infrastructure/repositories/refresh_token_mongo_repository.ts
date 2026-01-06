import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { RefreshToken, RefreshTokenPrimitives } from "../../domain/auth/refresh_token";

export class RefreshTokenMongoRepository extends MongoRepository<RefreshToken> {
  private static instance: RefreshTokenMongoRepository | null = null;

  private constructor() {
    super();
  }

  static getInstance(): RefreshTokenMongoRepository {
    if (!RefreshTokenMongoRepository.instance) {
      RefreshTokenMongoRepository.instance = new RefreshTokenMongoRepository();
    }
    return RefreshTokenMongoRepository.instance;
  }

  collectionName(): string {
    return "refresh_tokens";
  }

  async upsert(token: RefreshToken): Promise<void> {
    await this.persist(token.getId(), token);
  }

  async one(filter: object): Promise<RefreshTokenPrimitives | null> {
    const collection = await this.collection();
    const doc = await collection.findOne(filter);
    return doc ? (doc as unknown as RefreshTokenPrimitives) : null;
  }
}

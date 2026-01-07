import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { RefreshToken } from "../models/auth/refresh_token";

export class RefreshTokenMongoRepository
  extends MongoRepository<RefreshToken>
  implements IRepository<RefreshToken>
{
  private static instance: RefreshTokenMongoRepository | null = null;

  private constructor() {
    super(RefreshToken);
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
}

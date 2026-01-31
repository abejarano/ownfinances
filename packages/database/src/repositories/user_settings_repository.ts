import type { IRepository } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import type { Collection } from "mongodb";
import { UserSettings } from "../models/user_settings";

export class UserSettingsMongoRepository
  extends MongoRepository<UserSettings>
  implements IRepository<UserSettings>
{
  private static instance: UserSettingsMongoRepository | null = null;

  private constructor() {
    super(UserSettings);
  }

  static getInstance(): UserSettingsMongoRepository {
    if (!UserSettingsMongoRepository.instance) {
      UserSettingsMongoRepository.instance = new UserSettingsMongoRepository();
    }
    return UserSettingsMongoRepository.instance;
  }

  collectionName(): string {
    return "user_settings";
  }

  async ensureIndexes(collection: Collection): Promise<void> {
    await collection.createIndex({ userId: 1 }, { unique: true });
  }

  // async getByUserId(userId: string): Promise<UserSettings | null> {
  //   const collection = await this.collection();
  //   const doc = await collection.findOne({ userId });
  //   if (!doc) return null;
  //   return UserSettings.fromPrimitives(doc as any);
  // }

  async upsertSettings(settings: UserSettings): Promise<void> {
    const collection = await this.collection();
    await collection.updateOne(
      { userId: settings.getUserId() },
      { $set: settings.toPrimitives() },
      { upsert: true },
    );
  }
}

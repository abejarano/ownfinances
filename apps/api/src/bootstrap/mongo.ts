import { MongoClientFactory } from "@abejarano/ts-mongodb-criteria";

export async function getMongoClient() {
  return MongoClientFactory.createClient();
}

export async function closeMongoClient(): Promise<void> {
  await MongoClientFactory.closeClient();
}

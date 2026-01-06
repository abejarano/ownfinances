import type { Criteria, Paginate } from "@abejarano/ts-mongodb-criteria";
import { MongoRepository } from "@abejarano/ts-mongodb-criteria";
import { User, UserPrimitives } from "../../domain/auth/user";

export class UserMongoRepository extends MongoRepository<User> {
  private static instance: UserMongoRepository | null = null;

  private constructor() {
    super();
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

  async upsert(user: User): Promise<void> {
    await this.persist(user.getId(), user);
  }

  async one(filter: object): Promise<UserPrimitives | null> {
    const collection = await this.collection();
    const doc = await collection.findOne(filter);
    return doc ? (doc as unknown as UserPrimitives) : null;
  }

  async findByEmail(email: string): Promise<UserPrimitives | null> {
    return this.one({ email });
  }

  async ensureIndexes(): Promise<void> {
    const collection = await this.collection();
    await collection.createIndex({ email: 1 }, { unique: true });
  }

  async list(criteria: Criteria): Promise<Paginate<UserPrimitives>> {
    const documents = await this.searchByCriteria<UserPrimitives>(criteria);
    const pagination = await this.paginate(documents);
    return {
      ...pagination,
      results: pagination.results,
    };
  }
}

import type { IJob } from "@desquadra/queue";
import {
  CategoryMongoRepository,
  UserMongoRepository,
  UserSettingsMongoRepository,
} from "@desquadra/database";
import { categorizeCsvWithGemini } from "./service/clasificador.gemini.service.ts";

export class CategorizerTransactions implements IJob {
  constructor(
    private readonly categoryRepo: CategoryMongoRepository,
    private readonly userRepo: UserMongoRepository,
    private readonly userSettingsRepo: UserSettingsMongoRepository,
  ) {}

  async handle(args: any): Promise<any | void> {
    const categories = await this.categoryRepo.search(args.userId);

    const user = await this.userRepo.one({ userId: args.userId });

    if (!user) {
      throw Error(`No user with id ${args.userId}`);
    }

    const userSettings = await this.userSettingsRepo.one({
      userId: args.userId,
    });

    if (!userSettings) {
      throw Error(`No user settings with id ${args.userId}`);
    }

    const response = await categorizeCsvWithGemini({
      userName: user.getName(),
      userCountry: userSettings.getCountryCode() || "BR",
      csv: args.file,
      categories: JSON.stringify(categories),
    });

    console.log(response);
  }
}

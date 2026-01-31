import type { IJob } from "@desquadra/queue";
import { CategoryMongoRepository } from "@desquadra/database";
import { categorizeCsvWithGemini } from "./service/clasificador.gemini.service.ts";

export class CategorizerTransactions implements IJob {
  constructor(private readonly categoryRepo: CategoryMongoRepository) {}

  async handle(args: any): Promise<any | void> {
    const categories = await this.categoryRepo.search(args.userId);

    const response = await categorizeCsvWithGemini(
      args.file,
      JSON.stringify(categories),
    );

    console.log(response);
  }
}

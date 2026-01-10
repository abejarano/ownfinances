import type { ImportJobMongoRepository } from "../../repositories/import_job_repository";
import { notFound } from "../errors";
import type { ImportJobPrimitives } from "../../models/import_job";

export class ImportJobsController {
  constructor(
    private readonly importJobRepo: ImportJobMongoRepository
  ) {}

  async getById({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const job = await this.importJobRepo.one({
      userId: userId ?? "",
      importJobId: params.id,
    });
    if (!job) {
      return notFound(set, "Import job não encontrado");
    }
    return job.toPrimitives();
  }
}

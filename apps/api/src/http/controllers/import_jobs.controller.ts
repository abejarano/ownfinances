import type { ImportJobMongoRepository } from "../../repositories/import_job_repository"
import {
  Controller,
  Get,
  Param,
  Req,
  Res,
  type ServerResponse,
} from "bun-platform-kit"
import type { AuthenticatedRequest } from "../../@types/request"
import { HttpResponse } from "../../bootstrap/response"
import { Deps } from "../../bootstrap/deps"

@Controller("/imports")
export class ImportJobsController {
  private readonly importJobRepo: ImportJobMongoRepository
  constructor() {
    const deps = Deps.getInstance()
    this.importJobRepo = deps.importJobRepo
  }

  @Get("/:id")
  async getById(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const job = await this.importJobRepo.one({
      userId: req.userId ?? "",
      importJobId: id,
    })

    if (!job) {
      return HttpResponse(res, {
        status: 404,
        value: { message: "Import job not found" },
      })
    }

    return HttpResponse(res, { status: 200, value: job.toPrimitives() })
  }
}

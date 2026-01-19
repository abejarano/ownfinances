import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
  Res,
  Use,
  type ServerResponse,
} from "bun-platform-kit"
import type { AuthenticatedRequest } from "../../@types/request"
import { Deps } from "../../bootstrap/deps"
import { HttpResponse } from "../../bootstrap/response"
import type { TemplateService } from "../../services/template_service"
import { AuthMiddleware } from "../middleware/auth.middleware"
import {
  validateTemplatePayload,
  type TemplateCreatePayload,
  type TemplateUpdatePayload,
} from "../validation/templates.validation"

@Controller("/templates")
export class TemplatesController {
  private readonly service: TemplateService

  constructor() {
    this.service = Deps.resolve<TemplateService>("templateService")
  }

  @Get("/")
  @Use([AuthMiddleware])
  async list(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const limit = query.limit ? Number(query.limit) : 50
    const page = query.page ? Number(query.page) : 1
    const result = await this.service.list(req.userId ?? "", limit, page)
    // const payload = {
    //   ...result,
    //   results: result.results.map((item) =>
    //     TransactionTemplate.fromPrimitives(item).toPrimitives()
    //   ),
    // }
    return HttpResponse(res, result)
  }

  @Post("/")
  @Use([AuthMiddleware, validateTemplatePayload(false)])
  async create(
    @Body() body: TemplateCreatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.create(req.userId ?? "", body)
    return HttpResponse(res, result)
  }

  @Get("/:id")
  @Use([AuthMiddleware])
  async getById(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.getById(req.userId ?? "", id)

    return HttpResponse(res, result)
  }

  @Put("/:id")
  @Use([AuthMiddleware, validateTemplatePayload(true)])
  async update(
    @Param("id") id: string,
    @Body() body: TemplateUpdatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.update(req.userId ?? "", id, body)

    return HttpResponse(res, result)
  }

  @Delete("/:id")
  @Use([AuthMiddleware])
  async remove(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.delete(req.userId ?? "", id)
    if (result?.error) {
      return HttpResponse(res, { error: result.error, status: 404 })
    }
    return HttpResponse(res, { value: { ok: true }, status: 200 })
  }
}

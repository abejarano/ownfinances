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
import type { DebtMongoRepository } from "../../repositories/debt_repository"
import type { DebtsService } from "../../services/debts_service"
import { buildDebtsCriteria } from "../criteria/debts.criteria"
import { AuthMiddleware } from "../middleware/auth.middleware"
import {
  validateDebtPayload,
  type DebtCreatePayload,
  type DebtUpdatePayload,
} from "../validation/debts.validation"

@Controller("/debts")
export class DebtsController {
  private readonly repo: DebtMongoRepository
  private readonly service: DebtsService

  constructor() {
    const deps = Deps.getInstance()
    this.repo = deps.debtRepo
    this.service = deps.debtsService
  }

  @Get("/overview")
  @Use([AuthMiddleware])
  async overview(@Req() req: AuthenticatedRequest, @Res() res: ServerResponse) {
    try {
      if (!req.userId) {
        return HttpResponse(res, {
          status: 401,
          error: "Unauthorized: Missing Main User ID",
        })
      }
      const result = await this.service.overview(req.userId)
      return HttpResponse(res, result)
    } catch (e) {
      console.error("Error in DebtsController.overview:", e)
      return HttpResponse(res, {
        status: 500,
        error: "Internal server error",
      })
    }
  }

  @Get("/")
  @Use([AuthMiddleware])
  async list(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const criteria = buildDebtsCriteria(query, req.userId ?? "")
    const result = await this.service.list(req.userId ?? "", criteria)
    return HttpResponse(res, result)
  }

  @Get("/:id/summary")
  @Use([AuthMiddleware])
  async summary(
    @Param("id") id: string,
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.summary(
      req.userId ?? "",
      id,
      query.month
    )
    return HttpResponse(res, result)
  }

  @Get("/history/:id")
  @Use([AuthMiddleware])
  async history(
    @Param("id") id: string,
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.history(req.userId ?? "", id, query.month)

    return HttpResponse(res, result)
  }

  @Post("/")
  @Use([AuthMiddleware, validateDebtPayload(false)])
  async create(
    @Body() body: DebtCreatePayload,
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
    const debt = await this.repo.one({
      userId: req.userId ?? "",
      debtId: id,
    })
    if (!debt)
      return HttpResponse(res, {
        status: 404,
        value: "Deuda no encontrada",
      })

    return HttpResponse(res, {
      value: debt.toPrimitives(),
      status: 200,
    })
  }

  @Put("/:id")
  @Use([AuthMiddleware, validateDebtPayload(true)])
  async update(
    @Body() body: DebtUpdatePayload,
    @Param("id") id: string,
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
    console.log("ANGELLLL")

    try {
      console.log("DebtsController.remove called with id:", id)
      if (!req.userId) {
        return HttpResponse(res, { status: 401, error: "Unauthorized" })
      }
      return HttpResponse(res, await this.service.remove(req.userId, id))
    } catch (e: any) {
      console.error("DebtsController.remove error:", e)
      return HttpResponse(res, {
        status: 400,
        error: `Bad Request: ${e.message || e}`,
      })
    }
  }
}

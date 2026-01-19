import type { DebtMongoRepository } from "../../repositories/debt_repository"
import { Debt } from "../../models/debt"
import type { DebtPrimitives } from "../../models/debt"
import type { DebtsService } from "../../services/debts_service"
import { buildDebtsCriteria } from "../criteria/debts.criteria"
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Req,
  Res,
  Use,
  type ServerResponse,
} from "bun-platform-kit"
import type { AuthenticatedRequest } from "../../@types/request"
import { HttpResponse } from "../../bootstrap/response"
import {
  validateDebtPayload,
  type DebtCreatePayload,
  type DebtUpdatePayload,
} from "../validation/debts.validation"
import { AuthMiddleware } from "../middleware/auth.middleware"
import { Deps } from "../../bootstrap/deps"

@Controller("/debts")
export class DebtsController {
  private readonly repo: DebtMongoRepository
  private readonly service: DebtsService

  constructor() {
    const deps = Deps.getInstance()
    this.repo = deps.debtRepo
    this.service = deps.debtsService
  }

  @Get("/")
  @Use([AuthMiddleware])
  async list(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const criteria = buildDebtsCriteria(query, req.userId ?? "")
    const result = await this.repo.list<DebtPrimitives>(criteria)
    return HttpResponse(res, {
      value: {
        ...result,
        results: result.results.map((item) =>
          Debt.fromPrimitives(item).toPrimitives()
        ),
      },
      status: 200,
    })
  }

  @Get("/summary/:id")
  async summary(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.summary(req.userId ?? "", id)
    return HttpResponse(res, result)
  }

  @Get("/history/:id")
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
    const result = await this.service.remove(req.userId ?? "", id)
    return HttpResponse(res, result)
  }
}

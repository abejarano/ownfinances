import type {
  BudgetMongoRepository,
  BudgetPeriodType,
  BudgetPrimitives,
} from "@desquadra/database"
import { computePeriodRange, getRangeAnchorDate } from "../../helpers/dates"
import type { BudgetsService } from "../../services/budgets_service"
import { buildBudgetsCriteria } from "../criteria/budgets.criteria"

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
  type ServerResponse,
  Use,
} from "bun-platform-kit"
import { Deps } from "../../bootstrap/deps"
import { AuthMiddleware } from "../middleware/auth.middleware"

import type { AuthenticatedRequest } from "../../@types/request"
import { HttpResponse } from "../../bootstrap/response"
import {
  type BudgetCreatePayload,
  validateBudgetPayload,
} from "../validation/budgets.validation"

@Controller("/budgets")
export class BudgetsController {
  private repo: BudgetMongoRepository
  private service: BudgetsService

  constructor() {
    const deps = Deps.getInstance()
    this.repo = deps.budgetRepo
    this.service = deps.budgetsService
  }

  @Get("/")
  @Use([AuthMiddleware])
  async list(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    try {
      const criteria = buildBudgetsCriteria(query, req.userId ?? "")
      const result = await this.repo.list<BudgetPrimitives>(criteria)

      return HttpResponse(res, { value: result, status: 200 })
    } catch (error) {
      console.error("Error fetching budgets:", error)
      throw error
    }
  }

  @Post("/")
  @Use([AuthMiddleware, validateBudgetPayload(false)])
  async create(
    @Body() body: BudgetCreatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const response = await this.service.create(req.userId ?? "", body)
    return HttpResponse(res, response)
  }

  @Get("/current")
  @Use([AuthMiddleware])
  async current(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const period = query.period as BudgetPeriodType | undefined
    const dateRaw = query.date
    const parsedDate = dateRaw ? new Date(dateRaw) : new Date()
    if (!period)
      return HttpResponse(res, { error: "Falta el periodo", status: 400 })

    if (Number.isNaN(parsedDate.getTime()))
      return HttpResponse(res, { error: "Fecha invalida", status: 400 })

    const range = computePeriodRange(period, dateRaw ?? parsedDate)
    const anchorDate = getRangeAnchorDate(range)
    const budget = await this.repo.one({
      userId: req.userId ?? "",
      periodType: period,
      startDate: { $lte: anchorDate } as any,
      endDate: { $gte: anchorDate } as any,
    })

    if (!budget) {
      return HttpResponse(res, { value: { budget: null, range }, status: 200 })
    }

    return HttpResponse(res, {
      value: { budget: budget.toPrimitives(), range },
      status: 200,
    })
  }

  @Get("/:id")
  @Use([AuthMiddleware])
  async getById(
    @Param("/:id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const budget = await this.repo.one({
      userId: req.userId ?? "",
      budgetId: id,
    })
    if (!budget)
      return HttpResponse(res, {
        error: "Presupuesto no encontrado",
        status: 404,
      })

    return HttpResponse(res, { value: budget.toPrimitives(), status: 200 })
  }

  @Put("/:id")
  @Patch("/:id")
  @Use([AuthMiddleware, validateBudgetPayload(true)])
  async update(
    @Param("id") id: string,
    @Body() body: BudgetCreatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const response = await this.service.update(req.userId ?? "", id, body)

    return HttpResponse(res, response)
  }

  @Delete("/:id")
  @Use([AuthMiddleware])
  async remove(
    @Param("id") id: string,
    @Body() body: BudgetCreatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const deleted = await this.repo.delete(req.userId ?? "", id)
    if (!deleted) {
      return HttpResponse(res, {
        error: "Presupuesto no encontrado",
        status: 404,
      })
    }

    return HttpResponse(res, { value: { ok: true }, status: 200 })
  }

  @Delete("/current/lines/:categoryId")
  @Use([AuthMiddleware])
  async removeLine(
    @Param("categoryId") categoryId: string,
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const period = query.period as BudgetPeriodType | undefined
    const dateRaw = query.date
    const parsedDate = dateRaw ? new Date(dateRaw) : new Date()

    if (!period) {
      return HttpResponse(res, { error: "Falta el periodo", status: 400 })
    }
    if (Number.isNaN(parsedDate.getTime())) {
      return HttpResponse(res, { error: "Fecha invalida", status: 400 })
    }

    const range = computePeriodRange(period, dateRaw ?? parsedDate)
    const anchorDate = getRangeAnchorDate(range)
    const response = await this.service.removeLine(
      req.userId ?? "",
      period,
      anchorDate,
      categoryId
    )

    return HttpResponse(res, response)
  }
}

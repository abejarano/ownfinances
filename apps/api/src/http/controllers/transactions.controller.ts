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
import { Deps } from "../../bootstrap/deps"
import { HttpResponse } from "../../bootstrap/response"
import type { TransactionPrimitives } from "../../models/transaction"
import { Transaction } from "../../models/transaction"
import type { TransactionMongoRepository } from "../../repositories/transaction_repository"
import type { ReportsService } from "../../services/reports_service"
import type { TransactionsService } from "../../services/transactions_service"
import { buildTransactionsCriteria } from "../criteria/transactions.criteria"
import { AuthMiddleware } from "../middleware/auth.middleware"
import {
  validateTransactionPayload,
  type TransactionCreatePayload,
  type TransactionUpdatePayload,
} from "../validation/transactions.validation"

@Controller("/transactions")
export class TransactionsController {
  private readonly repo: TransactionMongoRepository
  private readonly service: TransactionsService
  private readonly reports: ReportsService

  constructor() {
    this.repo = Deps.resolve<TransactionMongoRepository>("transactionRepo")
    this.service = Deps.resolve<TransactionsService>("transactionsService")
    this.reports = Deps.resolve<ReportsService>("reportsService")
  }

  @Get("/")
  @Use([AuthMiddleware])
  async list(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const criteria = buildTransactionsCriteria(query, req.userId ?? "")
    const result = await this.repo.list<TransactionPrimitives>(criteria)
    const payload = {
      ...result,
      results: result.results.map((item) =>
        Transaction.fromPrimitives(item).toPrimitives()
      ),
    }
    return HttpResponse(res, { value: payload, status: 200 })
  }

  @Post("/")
  @Use([AuthMiddleware, validateTransactionPayload(false)])
  async create(
    @Body() body: TransactionCreatePayload,
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.create(req.userId ?? "", body)
    if (result.error) return HttpResponse(res, result)
    const impact = await this._impactFor(req.userId ?? "", result.value!, query)
    const payload = impact ? { ...result.value!, impact } : result.value!
    return HttpResponse(res, { value: payload, status: result.status })
  }

  @Get("/:id")
  @Use([AuthMiddleware])
  async getById(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const transaction = await this.repo.one({
      userId: req.userId ?? "",
      transactionId: id,
    })
    if (!transaction || transaction.toPrimitives().deletedAt) {
      return HttpResponse(res, {
        error: "Transacao nao encontrada",
        status: 404,
      })
    }
    return HttpResponse(res, {
      value: transaction.toPrimitives(),
      status: 200,
    })
  }

  @Put("/:id")
  @Use([AuthMiddleware, validateTransactionPayload(true)])
  async update(
    @Param("id") id: string,
    @Body() body: TransactionUpdatePayload,
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.update(req.userId ?? "", id, body)
    if (result.error) return HttpResponse(res, result)
    const impact = await this._impactFor(req.userId ?? "", result.value!, query)
    const payload = impact ? { ...result.value!, impact } : result.value!
    return HttpResponse(res, { value: payload, status: result.status })
  }

  @Delete("/:id")
  @Use([AuthMiddleware])
  async remove(
    @Param("id") id: string,
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const existing = await this.repo.one({
      userId: req.userId ?? "",
      transactionId: id,
    })
    const result = await this.service.remove(req.userId ?? "", id)
    if (result.error) return HttpResponse(res, result)
    const impact = existing
      ? await this._impactFor(req.userId ?? "", existing.toPrimitives(), query)
      : null
    const payload = impact ? { ok: true, impact } : { ok: true }
    return HttpResponse(res, { value: payload, status: result.status })
  }

  @Patch("/:id/clear")
  @Use([AuthMiddleware])
  async clear(
    @Param("id") id: string,
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.clear(req.userId ?? "", id)
    if (result.error) return HttpResponse(res, result)
    const impact = await this._impactFor(req.userId ?? "", result.value!, query)
    const payload = impact ? { ...result.value!, impact } : result.value!
    return HttpResponse(res, { value: payload, status: result.status })
  }

  @Patch("/:id/restore")
  @Use([AuthMiddleware])
  async restore(
    @Param("id") id: string,
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.restore(req.userId ?? "", id)
    if (result.error) return HttpResponse(res, result)
    const impact = await this._impactFor(req.userId ?? "", result.value!, query)
    const payload = impact ? { ...result.value!, impact } : result.value!
    return HttpResponse(res, { value: payload, status: result.status })
  }

  private async _impactFor(
    userId: string,
    transaction: TransactionPrimitives,
    query?: Record<string, string | undefined>
  ) {
    const includeImpact =
      query?.includeImpact === "true" || query?.impact === "true"
    if (!includeImpact) return null
    const period = (query.period as any) ?? "monthly"
    const date = transaction.date ?? new Date()
    const summary = await this.reports.summary(userId, period, date)
    const balances = await this.reports.balances(userId, period, date)
    return {
      summary,
      balances,
    }
  }

  @Get("/pending")
  @Use([AuthMiddleware])
  async listPending(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const limit = Number(query.limit || 50)
    const page = Number(query.page || 1)

    // Build filters for pending recurring transactions
    const filters: any[] = [
      { field: "userId", operator: "EQUAL", value: req.userId ?? "" },
      { field: "status", operator: "EQUAL", value: "pending" },
      { field: "recurringRuleId", operator: "EXISTS", value: true },
    ]

    // Optional filters
    if (query.month) {
      // month format: YYYY-MM
      const [year, month] = query.month.split("-").map(Number)
      const startDate = new Date(year!, month! - 1, 1)
      const endDate = new Date(year!, month!, 0, 23, 59, 59, 999)
      filters.push({
        field: "date",
        operator: "BETWEEN",
        value: { start: startDate, end: endDate },
      })
    }

    if (query.categoryId) {
      filters.push({
        field: "categoryId",
        operator: "EQUAL",
        value: query.categoryId,
      })
    }

    if (query.recurringRuleId) {
      filters.push({
        field: "recurringRuleId",
        operator: "EQUAL",
        value: query.recurringRuleId,
      })
    }

    const criteria = {
      filters: { values: filters.map((f) => new Map(Object.entries(f))) },
      order: { orderBy: "date", orderType: "ASC" },
      limit,
      page,
    }

    const result = await this.repo.list<TransactionPrimitives>(criteria as any)
    const payload = {
      ...result,
      results: result.results.map((item) =>
        Transaction.fromPrimitives(item).toPrimitives()
      ),
    }
    return HttpResponse(res, { value: payload, status: 200 })
  }

  @Post("/confirm-batch")
  @Use([AuthMiddleware])
  async confirmBatch(
    @Body() body: { transactionIds: string[] },
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    if (!body.transactionIds || body.transactionIds.length === 0) {
      return HttpResponse(res, {
        error: "No transaction IDs provided",
        status: 400,
      })
    }

    const confirmed = await this.repo.confirmBatch(
      body.transactionIds,
      req.userId ?? ""
    )

    return HttpResponse(res, { value: { confirmed }, status: 200 })
  }
}

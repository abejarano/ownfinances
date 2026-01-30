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
import type { DebtTransactionPrimitives } from "@desquadra/database"
import { DebtTransaction } from "@desquadra/database"
import type { DebtTransactionMongoRepository } from "@desquadra/database"
import type { DebtTransactionsService } from "../../services/debt_transactions_service"
import { buildDebtTransactionsCriteria } from "../criteria/debt_transactions.criteria"
import { AuthMiddleware } from "../middleware/auth.middleware"
import {
  validateDebtTransactionPayload,
  type DebtTransactionCreatePayload,
} from "../validation/debt_transactions.validation"

@Controller("/debt_transactions")
export class DebtTransactionsController {
  private readonly repo: DebtTransactionMongoRepository
  private readonly service: DebtTransactionsService

  constructor() {
    const deps = Deps.getInstance()
    this.repo = deps.debtTransactionRepo
    this.service = deps.debtTransactionsService
  }

  @Get("/")
  @Use([AuthMiddleware])
  async list(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const criteria = buildDebtTransactionsCriteria(query, req.userId)
    const result = await this.repo.list<DebtTransactionPrimitives>(criteria)
    return HttpResponse(res, {
      value: {
        nextPag: result.nextPag,
        count: result.count,
        results: result.results.map((item) =>
          DebtTransaction.fromPrimitives(item).toPrimitives()
        ),
      },
      status: 200,
    })
  }

  @Get("/:id")
  @Use([AuthMiddleware])
  async getById(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const item = await this.repo.one({
      userId: req.userId ?? "",
      debtTransactionId: id,
    })

    if (!item)
      return HttpResponse(res, {
        status: 404,
        value: "Movimiento no encontrado",
      })

    return HttpResponse(res, {
      value: item.toPrimitives(),
      status: 200,
    })
  }

  @Post("/")
  @Use([AuthMiddleware, validateDebtTransactionPayload(false)])
  async create(
    @Body() body: DebtTransactionCreatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.create(req.userId ?? "", body)
    return HttpResponse(res, result)
  }

  @Put("/:id")
  @Use([AuthMiddleware, validateDebtTransactionPayload(true)])
  async update(
    @Body() body: DebtTransactionCreatePayload,
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

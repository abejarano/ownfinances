import {
  Controller,
  Get,
  Query,
  Req,
  Res,
  Use,
  type ServerResponse,
} from "bun-platform-kit"
import type { AuthenticatedRequest } from "../../@types/request"
import { Deps } from "../../bootstrap/deps"
import { HttpResponse } from "../../bootstrap/response"
import type { BudgetPeriodType } from "../../models/budget"
import type { ReportsService } from "../../services/reports_service"
import { AuthMiddleware } from "../middleware/auth.middleware"

@Controller("/reports")
export class ReportsController {
  private readonly reports: ReportsService

  constructor() {
    this.reports = Deps.resolve<ReportsService>("reportsService")
  }

  @Get("/summary")
  @Use([AuthMiddleware])
  async summary(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const period = query.period as BudgetPeriodType | undefined
    const date = query.date ? new Date(query.date) : new Date()

    if (!period)
      return HttpResponse(res, { error: "Falta el periodo", status: 400 })

    if (Number.isNaN(date.getTime()))
      return HttpResponse(res, { error: "Fecha invalida", status: 400 })

    const result = await this.reports.summary(req.userId ?? "", period, date)
    return HttpResponse(res, result)
  }

  @Get("/balances")
  @Use([AuthMiddleware])
  async balances(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const period = query.period as BudgetPeriodType | undefined
    const date = query.date ? new Date(query.date) : new Date()

    if (!period)
      return HttpResponse(res, { error: "Falta el periodo", status: 400 })

    if (Number.isNaN(date.getTime()))
      return HttpResponse(res, { error: "Fecha invalida", status: 400 })

    const result = await this.reports.balances(req.userId ?? "", period, date)
    return HttpResponse(res, result)
  }
}

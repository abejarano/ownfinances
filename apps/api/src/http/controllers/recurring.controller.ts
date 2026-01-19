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
import type { RecurringService } from "../../services/recurring_service"
import { AuthMiddleware } from "../middleware/auth.middleware"
import {
  validateRecurringMaterializePayload,
  validateRecurringRulePayload,
  validateRecurringSplitPayload,
  type RecurringRuleCreatePayload,
} from "../validation/recurring.validation"

@Controller("/recurring_rules")
export class RecurringController {
  private readonly service: RecurringService

  constructor() {
    this.service = Deps.resolve<RecurringService>("recurringService")
  }

  @Post("/")
  @Use([AuthMiddleware, validateRecurringRulePayload(false)])
  async create(
    @Body() body: RecurringRuleCreatePayload,
    @Req() req: { userId: string },
    @Res() res: ServerResponse
  ) {
    const result = await this.service.create(req.userId, {
      frequency: body.frequency,
      interval: body.interval || 1,
      startDate: new Date(body.startDate),
      endDate: body.endDate ? new Date(body.endDate) : undefined,
      template: {
        type: body.template.type,
        amount: Number(body.template.amount),
        currency: body.template.currency || "BRL",
        categoryId: body.template.categoryId,
        fromAccountId: body.template.fromAccountId,
        toAccountId: body.template.toAccountId,
        note: body.template.note,
        tags: body.template.tags,
      },
    })

    return HttpResponse(res, result)
  }

  @Get("/")
  @Use([AuthMiddleware])
  async list(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const limit = Number(query.limit || 50)
    const page = Number(query.page || 1)
    const result = await this.service.list(req.userId!, limit, page)

    return HttpResponse(res, result)
  }

  @Get("/preview")
  @Use([AuthMiddleware])
  async preview(
    @Query() query: { period: string; date?: string; month?: string },
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const period = (query.period as "monthly") || "monthly"
    let date: Date

    if (query.month) {
      // Parse YYYY-MM format
      const [year, month] = query.month.split("-").map(Number)
      date = new Date(year!, month! - 1, 1)
    } else if (query.date) {
      date = new Date(query.date)
    } else {
      date = new Date()
    }

    const result = await this.service.preview(req.userId!, period, date)
    return HttpResponse(res, result)
  }

  @Get("/pending-summary")
  @Use([AuthMiddleware])
  async getPendingSummary(
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const currentDate = new Date()
    const result = await this.service.getPendingSummary(
      req.userId!,
      currentDate
    )
    return HttpResponse(res, result)
  }

  @Get("/summary-by-month")
  @Use([AuthMiddleware])
  async getSummaryByMonth(
    @Query() query: { months?: string },
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const months = Number(query?.months || 3)
    const result = await this.service.getSummaryByMonth(req.userId!, months)
    return HttpResponse(res, result)
  }

  @Get("/catchup")
  @Use([AuthMiddleware])
  async getCatchupSummary(
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.getCatchupSummary(req.userId!)
    return HttpResponse(res, result)
  }

  @Get("/:id")
  @Use([AuthMiddleware])
  async getById(
    @Param("id") id: string,
    @Req() req: { userId: string },
    @Res() res: ServerResponse
  ) {
    const result = await this.service.getById(req.userId, id)
    return HttpResponse(res, result)
  }

  @Put("/:id")
  @Use([AuthMiddleware, validateRecurringRulePayload(true)])
  async update(
    @Body() body: any,
    @Param("id") id: string,
    @Req() req: { userId: string },
    @Res() res: ServerResponse
  ) {
    const result = await this.service.update(req.userId, id, {
      frequency: body.frequency,
      interval: body.interval,
      startDate: body.startDate ? new Date(body.startDate) : undefined,
      endDate: body.endDate ? new Date(body.endDate) : undefined,
      isActive: body.isActive,
      template: body.template
        ? {
            type: body.template.type,
            amount: Number(body.template.amount),
            currency: body.template.currency || "BRL",
            categoryId: body.template.categoryId,
            fromAccountId: body.template.fromAccountId,
            toAccountId: body.template.toAccountId,
            note: body.template.note,
            tags: body.template.tags,
          }
        : undefined,
    })

    return HttpResponse(res, result)
  }

  @Delete("/:id")
  @Use([AuthMiddleware])
  async delete(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.delete(req.userId!, id)
    return HttpResponse(res, result)
  }

  @Post("/run")
  @Use([AuthMiddleware])
  async run(
    @Body() body: { period?: string; date?: string; month?: string },
    @Query() query: { period?: string; date?: string; month?: string },
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const queryPeriod = query?.period
    const queryDate = query?.date
    const queryMonth = query?.month
    const bodyMonth = body?.month

    const period =
      (queryPeriod as "monthly") || (body?.period as "monthly") || "monthly"

    let date: Date
    const monthParam = queryMonth || bodyMonth

    if (monthParam) {
      // Parse YYYY-MM format
      const [year, month] = monthParam.split("-").map(Number)
      date = new Date(year!, month! - 1, 1)
    } else if (queryDate) {
      date = new Date(queryDate)
    } else if (body?.date) {
      date = new Date(body.date)
    } else {
      date = new Date()
    }

    const result = await this.service.run(req.userId!, period, date)
    return HttpResponse(res, result)
  }

  @Post("/:id/materialize")
  @Use([AuthMiddleware, validateRecurringMaterializePayload()])
  async materialize(
    @Param("id") id: string,
    @Body() body: { date: string },

    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const date = new Date(body.date)
    const tx = await this.service.materialize(req.userId!, id, date)

    return HttpResponse(res, tx)
  }

  @Post("/:id/split")
  @Use([AuthMiddleware, validateRecurringSplitPayload()])
  async split(
    @Param("id") id: string,
    @Body() body: { date: string; template: any },
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const date = new Date(body.date)
    const result = await this.service.split(
      req.userId!,
      id,
      date,
      body.template
    )
    return HttpResponse(res, result)
  }

  @Post("/:id/ignore")
  @Use([AuthMiddleware])
  async ignore(
    @Param("id") id: string,
    @Body() body: { date: string },
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const date = new Date(body.date)
    const result = await this.service.ignore(req.userId!, id, date)
    return HttpResponse(res, result)
  }

  @Post("/:id/undo-ignore")
  @Use([AuthMiddleware])
  async undoIgnore(
    @Param("id") id: string,
    @Body() body: { date: string },
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const date = new Date(body.date)
    const result = await this.service.undoIgnore(req.userId!, id, date)
    return HttpResponse(res, result)
  }
}

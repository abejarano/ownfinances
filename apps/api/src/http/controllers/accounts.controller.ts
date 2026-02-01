import {
  AccountMongoRepository,
  type AccountPrimitives,
} from "@desquadra/database"
import { Deps } from "../../bootstrap/deps"
import { HttpResponse } from "../../bootstrap/response"
import type { AccountsService } from "../../services/accounts_service"
import { buildAccountsCriteria } from "../criteria/accounts.criteria"
import { AuthMiddleware } from "../middleware/auth.middleware"
import {
  type AccountCreatePayload,
  type AccountUpdatePayload,
  validateAccountPayload,
} from "../validation/accounts.validation"

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
  type ServerResponse,
  Use,
} from "bun-platform-kit"
import type { AuthenticatedRequest } from "../../@types/request"

@Controller("/accounts")
export class AccountsController {
  private repo: AccountMongoRepository
  private service: AccountsService

  constructor() {
    const deps = Deps.getInstance()
    this.repo = Deps.resolve<AccountMongoRepository>("accountRepo")
    this.service = Deps.resolve<AccountsService>("accountsService")
  }

  @Post("/")
  @Use([AuthMiddleware, validateAccountPayload(false)])
  async create(
    @Body() body: AccountCreatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const account = await this.service.create(req.userId!, body)
    res.status(201).send(account)
  }

  @Get("/")
  @Use(AuthMiddleware)
  async list(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    try {
      const criteria = buildAccountsCriteria(query, req.userId!)

      const result = await this.repo.list<AccountPrimitives>(criteria)

      return HttpResponse(res, { value: result, status: 200 })
    } catch (e) {
      console.log(`errrr ${e}`)
      return HttpResponse(res, { error: "Error interno", status: 500 })
    }
  }

  @Get("/:id")
  async getById(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const account = await this.repo.one({
      userId: req.userId ?? "",
      accountId: id,
    })

    if (!account) return res.status(404).send("Cuenta não encontrada")

    res.status(200).send(account.toPrimitives())
  }

  @Put("/:id")
  @Use([AuthMiddleware, validateAccountPayload(true)])
  async update(
    @Param("id") id: string,
    @Body() body: AccountUpdatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const response = await this.service.update(req.userId ?? "", id, body)

    if (response.error) {
      return res.status(response.status).send(response.error)
    }

    return res.status(response.status).send(response.value)
  }

  @Delete("/:id")
  @Use([AuthMiddleware])
  async remove(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    return HttpResponse(res, await this.service.remove(req.userId ?? "", id))
  }

  @Get("/test/:id")
  async test(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    return HttpResponse(res, { status: 200, value: id })
  }
}

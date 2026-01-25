import type { TransactionsImportService } from "../../services/transactions_import_service"

import {
  Body,
  Controller,
  Post,
  Req,
  Res,
  Use,
  type ServerResponse,
} from "bun-platform-kit"
import type { AuthenticatedRequest } from "../../@types/request"
import { Deps } from "../../bootstrap/deps"
import { HttpResponse } from "../../bootstrap/response"
import { AuthMiddleware } from "../middleware/auth.middleware"

@Controller("/transactions")
export class TransactionsImportController {
  private readonly importService: TransactionsImportService
  constructor() {
    const deps = Deps.getInstance()
    this.importService = deps.transactionsImportService
  }

  @Post("/import")
  @Post("/import/preview")
  @Use([AuthMiddleware])
  async preview(
    @Body() body: any,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    try {
      const accountId = body.accountId
      //TODO hay que validar que funcione
      const file = req?.files?.file

      if (!file) {
        return HttpResponse(res, {
          status: 400,
          value: { message: "Falta o arquivo CSV" },
        })
      }

      const fileContent = typeof file === "string" ? file : await file.text()
      const result = await this.importService.process(
        req.userId ?? "",
        accountId,
        fileContent,
        "preview"
      )
      return HttpResponse(res, { status: 200, value: result })
    } catch (error: any) {
      return HttpResponse(res, {
        status: 400,
        value: { message: error.message || "Erro ao processar preview" },
      })
    }
  }

  @Post("/import")
  @Use([AuthMiddleware])
  async import(
    @Body() body: any,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    try {
      const accountId = body.accountId
      //TODO hay que validar que funcione
      const file = req?.files?.file

      if (!file) {
        return HttpResponse(res, {
          status: 400,
          value: { message: "Falta o arquivo CSV" },
        })
      }

      const fileContent = typeof file === "string" ? file : await file.text()
      const result = await this.importService.process(
        req.userId ?? "",
        accountId,
        fileContent,
        "import"
      )
      return HttpResponse(res, { status: 200, value: result })
    } catch (error: any) {
      return HttpResponse(res, {
        status: 400,
        value: { message: error.message || "Erro ao processar preview" },
      })
    }
  }
}

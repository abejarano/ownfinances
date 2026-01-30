//import type { TransactionsImportService } from "../../services/transactions_import_service"

import { QueueDispatcher, QueueName } from "@desquadra/queue"
import {
  Body,
  type BunMultipartFile,
  Controller,
  Post,
  Req,
  Res,
  type ServerResponse,
  Use,
} from "bun-platform-kit"
import type { AuthenticatedRequest } from "../../@types/request"
import { HttpResponse } from "../../bootstrap/response"
import { AuthMiddleware } from "../middleware/auth.middleware"

@Controller("/transactions")
export class TransactionsImportController {
  //private readonly importService: TransactionsImportService

  constructor() {
    //const deps = Deps.getInstance()
    //this.importService = deps.transactionsImportService
  }

  // @Post("/import")
  // @Use([AuthMiddleware])
  // async import(
  //   @Body() body: any,
  //   @Req() req: AuthenticatedRequest,
  //   @Res() res: ServerResponse
  // ) {
  //   try {
  //     const accountId = body.accountId
  //     //TODO hay que validar que funcione
  //     const file = req?.files?.file
  //
  //     QueueDispatcher.getInstance().dispatch(QueueName.CategorizeTransactions, {
  //       file,
  //     })
  //
  //     if (!file) {
  //       return HttpResponse(res, {
  //         status: 400,
  //         value: { message: "Falta o arquivo CSV" },
  //       })
  //     }
  //
  //     const fileContent = typeof file === "string" ? file : await file.text()
  //     const result = await this.importService.process(
  //       req.userId ?? "",
  //       accountId,
  //       fileContent,
  //       "import"
  //     )
  //     return HttpResponse(res, { status: 200, value: "ok" })
  //   } catch (error: any) {
  //     return HttpResponse(res, {
  //       status: 400,
  //       value: { message: error.message || "Erro ao processar preview" },
  //     })
  //   }
  // }

  @Post("/import/preview")
  @Use([AuthMiddleware])
  async preview(
    @Body() body: any,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    try {
      const accountId = body.accountId
      const file = req?.files?.file as BunMultipartFile

      if (!file) {
        return HttpResponse(res, {
          status: 400,
          value: { message: "Falta o arquivo CSV" },
        })
      }

      const fileContent = await file.text!()

      QueueDispatcher.getInstance().dispatch(QueueName.CategorizeTransactions, {
        file: fileContent,
        accountId,
        userId: req.userId,
      })

      // const result = await this.importService.process(
      //   req.userId ?? "",
      //   accountId,
      //   fileContent,
      //   "preview"
      // )
      return HttpResponse(res, { status: 200, value: "ok" })
    } catch (error: any) {
      return HttpResponse(res, {
        status: 400,
        value: { message: error.message || "Erro ao processar preview" },
      })
    }
  }
}

import {
  CategoryMongoRepository,
  UserMongoRepository,
  UserSettingsMongoRepository,
} from "@desquadra/database"
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
import { Deps } from "../../bootstrap/deps.ts"
import { HttpResponse } from "../../bootstrap/response"
import { AuthMiddleware } from "../middleware/auth.middleware"

@Controller("/transactions")
export class TransactionsImportController {
  constructor(
    private readonly categoryRepo: CategoryMongoRepository,
    private readonly userRepo: UserMongoRepository,
    private readonly userSettingsRepo: UserSettingsMongoRepository
  ) {
    this.categoryRepo = Deps.resolve<CategoryMongoRepository>("categoryRepo")
    this.userRepo = Deps.resolve<UserMongoRepository>("userRepo")
    this.userSettingsRepo =
      Deps.resolve<UserSettingsMongoRepository>("userSettingsRepo")
  }

  @Post("/import")
  @Use([AuthMiddleware])
  async importCsv(
    @Body() body: any,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    try {
      const accountId = body.accountId
      const file = req?.files?.file as BunMultipartFile
      const userId = req.userId!

      if (!file) {
        return HttpResponse(res, {
          status: 400,
          value: { message: "Falta o arquivo CSV" },
        })
      }

      const user = (await this.userRepo.one({ userId }))!

      const userSettings = await this.userSettingsRepo.one({
        userId,
      })

      if (!userSettings) {
        return HttpResponse(res, {
          status: 400,
          value: { message: "O Usuário não tem configuração" },
        })
      }

      const fileContent = await file.text!()

      QueueDispatcher.getInstance().dispatch<{
        userId: string
        userName: string
        accountId: string
        countryCode: string
        file: any
      }>(QueueName.CategorizeTransactions, {
        file: fileContent,
        accountId,
        userId,
        userName: user.getName(),
        countryCode: userSettings.getCountryCode()!,
      })

      return HttpResponse(res, { status: 200, value: { message: "ok" } })
    } catch (error: any) {
      return HttpResponse(res, {
        status: 400,
        value: { message: error.message || "Erro ao processar o import" },
      })
    }
  }
}

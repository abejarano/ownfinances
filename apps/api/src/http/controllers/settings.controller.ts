import {
  Body,
  Controller,
  Get,
  Put,
  Req,
  Res,
  Use,
  type ServerResponse,
} from "bun-platform-kit"
import type { AuthenticatedRequest } from "../../@types/request"
import { Deps } from "../../bootstrap/deps"
import { HttpResponse } from "../../bootstrap/response"
import { UserSettings } from "../../models/user_settings"
import type { UserSettingsRepository } from "../../repositories/user_settings_repository"
import { AuthMiddleware } from "../middleware/auth.middleware"

@Controller("/settings")
export class SettingsController {
  private readonly repo: UserSettingsRepository

  constructor() {
    this.repo = Deps.resolve<UserSettingsRepository>("userSettingsRepo")
  }

  @Get("/")
  @Use([AuthMiddleware])
  async get(@Req() req: AuthenticatedRequest, @Res() res: ServerResponse) {
    const userId = req.userId ?? ""
    let settings = await this.repo.getByUserId(userId)

    if (!settings) {
      // Create default settings if not exists
      settings = UserSettings.create(userId)
      await this.repo.upsertSettings(settings)
    }

    return HttpResponse(res, { value: settings.toPrimitives(), status: 200 })
  }

  @Put("/")
  @Use([AuthMiddleware])
  async update(
    @Body() body: { autoGenerateRecurring?: boolean },
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const userId = req.userId ?? ""
    let settings = await this.repo.getByUserId(userId)

    if (!settings) {
      settings = UserSettings.create(userId)
    }

    if (body.autoGenerateRecurring !== undefined) {
      settings.setAutoGenerateRecurring(body.autoGenerateRecurring)
    }

    await this.repo.upsertSettings(settings)

    return HttpResponse(res, { value: settings.toPrimitives(), status: 200 })
  }
}

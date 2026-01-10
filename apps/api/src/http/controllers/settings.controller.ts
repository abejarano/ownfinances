import type { UserSettingsRepository } from "../../repositories/user_settings_repository";
import { UserSettings } from "../../models/user_settings";

export class SettingsController {
  constructor(private readonly repo: UserSettingsRepository) {}

  async get(ctx: { userId: string }) {
    let settings = await this.repo.getByUserId(ctx.userId);
    
    if (!settings) {
      // Create default settings if not exists
      settings = UserSettings.create(ctx.userId);
      await this.repo.upsertSettings(settings);
    }
    
    return settings.toPrimitives();
  }

  async update(ctx: {
    userId: string;
    body: { autoGenerateRecurring?: boolean };
  }) {
    let settings = await this.repo.getByUserId(ctx.userId);
    
    if (!settings) {
      settings = UserSettings.create(ctx.userId);
    }
    
    if (ctx.body.autoGenerateRecurring !== undefined) {
      settings.setAutoGenerateRecurring(ctx.body.autoGenerateRecurring);
    }
    
    await this.repo.upsertSettings(settings);
    
    return settings.toPrimitives();
  }
}

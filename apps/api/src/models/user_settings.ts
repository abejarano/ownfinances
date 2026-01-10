export interface UserSettingsPrimitives {
  userId: string;
  autoGenerateRecurring: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export class UserSettings {
  private constructor(
    private readonly userId: string,
    private autoGenerateRecurring: boolean,
    private readonly createdAt: Date,
    private updatedAt: Date
  ) {}

  static create(userId: string): UserSettings {
    const now = new Date();
    return new UserSettings(userId, false, now, now);
  }

  static fromPrimitives(data: UserSettingsPrimitives): UserSettings {
    return new UserSettings(
      data.userId,
      data.autoGenerateRecurring,
      new Date(data.createdAt),
      new Date(data.updatedAt)
    );
  }

  toPrimitives(): UserSettingsPrimitives {
    return {
      userId: this.userId,
      autoGenerateRecurring: this.autoGenerateRecurring,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  getUserId(): string {
    return this.userId;
  }

  getId(): string {
    return this.userId;
  }

  getAutoGenerateRecurring(): boolean {
    return this.autoGenerateRecurring;
  }

  setAutoGenerateRecurring(value: boolean): void {
    this.autoGenerateRecurring = value;
    this.updatedAt = new Date();
  }
}

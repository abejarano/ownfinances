export interface UserSettingsPrimitives {
  userId: string
  autoGenerateRecurring: boolean
  primaryCurrency?: string | null
  countryCode?: string | null
  locale?: string | null
  createdAt: Date
  updatedAt: Date
}

export class UserSettings {
  private constructor(
    private readonly userId: string,
    private autoGenerateRecurring: boolean,
    private primaryCurrency: string | null,
    private countryCode: string | null,
    private locale: string | null,
    private readonly createdAt: Date,
    private updatedAt: Date
  ) {}

  static create(userId: string): UserSettings {
    const now = new Date()
    return new UserSettings(userId, false, null, null, null, now, now)
  }

  static fromPrimitives(data: UserSettingsPrimitives): UserSettings {
    return new UserSettings(
      data.userId,
      data.autoGenerateRecurring ?? false,
      data.primaryCurrency ?? null,
      data.countryCode ?? null,
      data.locale ?? null,
      new Date(data.createdAt),
      new Date(data.updatedAt)
    )
  }

  toPrimitives(): UserSettingsPrimitives {
    return {
      userId: this.userId,
      autoGenerateRecurring: this.autoGenerateRecurring,
      primaryCurrency: this.primaryCurrency,
      countryCode: this.countryCode,
      locale: this.locale,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    }
  }

  getUserId(): string {
    return this.userId
  }

  getId(): string {
    return this.userId
  }

  getAutoGenerateRecurring(): boolean {
    return this.autoGenerateRecurring
  }

  setAutoGenerateRecurring(value: boolean): void {
    this.autoGenerateRecurring = value
    this.updatedAt = new Date()
  }

  getPrimaryCurrency(): string | null {
    return this.primaryCurrency
  }

  setPrimaryCurrency(value: string | null): void {
    this.primaryCurrency = value
    this.updatedAt = new Date()
  }

  getCountryCode(): string | null {
    return this.countryCode
  }

  setCountryCode(value: string | null): void {
    this.countryCode = value
    this.updatedAt = new Date()
  }

  getLocale(): string | null {
    return this.locale
  }

  setLocale(value: string | null): void {
    this.locale = value
    this.updatedAt = new Date()
  }
}

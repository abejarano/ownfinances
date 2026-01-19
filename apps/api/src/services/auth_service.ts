import argon2 from "argon2"
import crypto from "node:crypto"
import type { Result } from "../bootstrap/response"
import { RefreshToken } from "../models/auth/refresh_token"
import { User, type UserPrimitives } from "../models/auth/user"
import { Category } from "../models/category"
import type { CategoryMongoRepository } from "../repositories/category_repository"
import type { RefreshTokenMongoRepository } from "../repositories/refresh_token_mongo_repository"
import type { UserMongoRepository } from "../repositories/user_mongo_repository"
import { env } from "../shared/env"

export type UserRegisterResponse = {
  user: { id: string; userId: string; email: string; name?: string | null }
  refreshToken: string
}

export class AuthService {
  constructor(
    private readonly users: UserMongoRepository,
    private readonly refreshTokens: RefreshTokenMongoRepository,
    private readonly categories: CategoryMongoRepository
  ) {}

  async register(payload: {
    email: string
    password: string
    name?: string
  }): Promise<Result<UserRegisterResponse>> {
    const email = payload.email?.trim().toLowerCase()
    const password = payload.password

    // if (!email) return { error: "Email obrigatório", };
    // if (!password) return { error: "Senha obrigatória" };

    const existing = await this.users.one({ email })
    if (existing) return { error: "Email já cadastrado", status: 400 }

    const passwordHash = await argon2.hash(password)

    const user = User.create({
      email,
      name: payload.name ?? null,
      passwordHash,
    })

    await this.users.upsert(user)
    await this.seedDefaultCategories(user.getUserId())

    const refresh = await this.issueRefreshToken(user.getUserId())
    return {
      value: {
        user: {
          id: user.getUserId(),
          name: user.getName(),
          userId: user.getUserId(),
          email: user.getEmail(),
        },

        refreshToken: refresh.refreshToken,
      },
      status: 200,
    }
  }

  async login(payload: {
    email: string
    password: string
  }): Promise<Result<UserRegisterResponse>> {
    const email = payload.email?.trim().toLowerCase()
    const password = payload.password

    const user = await this.users.one({ email })
    if (!user) return { error: "Credenciais inválidas", status: 403 }

    const userPrimitives = user.toPrimitives()
    const valid = await argon2.verify(userPrimitives.passwordHash, password)
    if (!valid) return { error: "Credenciais inválidas", status: 403 }

    const updated: UserPrimitives = {
      ...userPrimitives,
      id: userPrimitives.id ?? userPrimitives.userId,
      lastLoginAt: new Date(),
      updatedAt: new Date(),
    }

    await this.users.upsert(User.fromPrimitives(updated))

    const refresh = await this.issueRefreshToken(user.getUserId())
    return {
      status: 200,
      value: {
        user: {
          id: user.getId(),
          name: user.getName(),
          userId: user.getUserId(),
          email: user.getEmail(),
        },
        refreshToken: refresh.refreshToken,
      },
    }
  }

  async refresh(payload: {
    refreshToken?: string
    userAgent?: string
    ip?: string
  }): Promise<Result<{ userId: string; refreshToken: string }>> {
    if (!payload.refreshToken) {
      return { error: "Sessão expirada, entre novamente", status: 403 }
    }

    const tokenHash = hashToken(payload.refreshToken)
    const existing = await this.refreshTokens.one({ tokenHash })
    if (!existing) {
      return { error: "Sessão expirada, entre novamente", status: 403 }
    }

    const existingPrimitives = existing.toPrimitives()
    if (existingPrimitives.revokedAt) {
      return { error: "Sessão expirada, entre novamente", status: 403 }
    }

    if (existingPrimitives.expiresAt < new Date()) {
      return { error: "Sessão expirada, entre novamente", status: 403 }
    }

    const revoked = RefreshToken.fromPrimitives({
      ...existingPrimitives,
      id: existingPrimitives.id ?? existingPrimitives.refreshTokenId,
      revokedAt: new Date(),
    })
    await this.refreshTokens.upsert(revoked)

    const refresh = await this.issueRefreshToken(
      existingPrimitives.userId,
      payload.userAgent,
      payload.ip
    )
    return {
      status: 200,
      value: {
        userId: existingPrimitives.userId,
        refreshToken: refresh.refreshToken,
      },
    }
  }

  async logout(payload: {
    refreshToken?: string
  }): Promise<Result<{ ok: boolean }>> {
    if (!payload.refreshToken) {
      return { error: "Sessão expirada, entre novamente", status: 403 }
    }

    const tokenHash = hashToken(payload.refreshToken)
    const existing = await this.refreshTokens.one({ tokenHash })
    if (!existing) {
      return { error: "Sessão expirada, entre novamente", status: 403 }
    }

    const existingPrimitives = existing.toPrimitives()
    const revoked = RefreshToken.fromPrimitives({
      ...existingPrimitives,
      id: existingPrimitives.id ?? existingPrimitives.refreshTokenId,
      revokedAt: new Date(),
    })

    await this.refreshTokens.upsert(revoked)
    return { status: 200, value: { ok: true } }
  }

  async getMe(
    userId: string
  ): Promise<Result<{ userId: string; email: string; name?: string | null }>> {
    const user = await this.users.one({ userId })
    if (!user) return { error: "Sessão expirada, entre novamente", status: 403 }

    return {
      status: 200,
      value: {
        name: user.getName(),
        userId: user.getUserId(),
        email: user.getEmail(),
      },
    }
  }

  private async issueRefreshToken(
    userId: string,
    userAgent?: string,
    ip?: string
  ) {
    const refreshToken = generateRefreshToken()
    const now = new Date()
    const refreshTtlDays = env.REFRESH_TOKEN_TTL
    const expiresAt = new Date(
      now.getTime() + refreshTtlDays * 24 * 60 * 60 * 1000
    )

    const refreshEntity = RefreshToken.create({
      userId,
      tokenHash: hashToken(refreshToken),
      expiresAt,
      userAgent: userAgent ?? null,
      ip: ip ?? null,
    })

    await this.refreshTokens.upsert(refreshEntity)

    return {
      refreshToken,
    }
  }

  private async seedDefaultCategories(userId: string) {
    const categories = [
      {
        name: "Alimentacao",
        kind: "expense",
        color: "#F97316",
        icon: "restaurant",
      },
      {
        name: "Educacao",
        kind: "expense",
        color: "#7C3AED",
        icon: "education",
      },
      {
        name: "Lazer",
        kind: "expense",
        color: "#0EA5E9",
        icon: "leisure",
      },
      {
        name: "Moradia",
        kind: "expense",
        color: "#DB2777",
        icon: "home",
      },
      {
        name: "Emprestimos",
        kind: "expense",
        color: "#E11D48",
        icon: "shopping",
      },
      {
        name: "Salario",
        kind: "income",
        color: "#22C55E",
        icon: "salary",
      },
      {
        name: "Sporte",
        kind: "expense",
        color: "#06B6D4",
        icon: "health",
      },
      {
        name: "Transporte",
        kind: "expense",
        color: "#64748B",
        icon: "transport",
      },
    ] as const

    await Promise.all(
      categories.map((category) =>
        this.categories.upsert(
          Category.create({
            userId,
            name: category.name,
            kind: category.kind,
            color: category.color,
            icon: category.icon,
            isActive: true,
          })
        )
      )
    )
  }
}

function hashToken(token: string) {
  return crypto.createHash("sha256").update(token).digest("hex")
}

function generateRefreshToken() {
  return crypto.randomBytes(48).toString("base64url")
}

function toUserResponse(user: UserPrimitives) {
  return {
    id: user.userId,
    email: user.email,
    name: user.name ?? null,
  }
}

import appleSignin from "apple-signin-auth"
import argon2 from "argon2"
import { OAuth2Client } from "google-auth-library"
import crypto from "node:crypto"
import type { Result } from "../bootstrap/response"
import { Account, AccountType } from "../models/account"
import { RefreshToken } from "../models/auth/refresh_token"
import { User, type UserPrimitives } from "../models/auth/user"
import { Category } from "../models/category"
import { createMongoId } from "../models/shared/mongo_id"
import type { AccountMongoRepository } from "../repositories/account_repository"
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
    private readonly categories: CategoryMongoRepository,
    private readonly accounts: AccountMongoRepository
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

  async socialLogin(payload: {
    provider: "google" | "apple"
    token: string
    email?: string // Optional, used as fallback or for Apple relay
    name?: string
    socialId?: string // Optional, passed by client if available, but we verify token
  }): Promise<Result<UserRegisterResponse>> {
    try {
      // 1. Verify Token & Extract Info
      const verification = await this.verifySocialToken(
        payload.provider,
        payload.token
      )
      if (!verification) {
        return { error: "Token inválido ou expirado", status: 401 }
      }

      const { email: verifiedEmail, socialId: verifiedSocialId } = verification
      const email = verifiedEmail ?? payload.email
      const socialId = verifiedSocialId

      if (!socialId) {
        return { error: "Não foi possível identificar o usuário", status: 400 }
      }

      // 2. Lookup by Social ID
      let user: User | null = null

      if (payload.provider === "google") {
        user = await this.users.one({ googleId: socialId })
      } else {
        user = await this.users.one({ appleId: socialId })
      }

      // 3. Lookup by Email (Link Account)
      if (!user && email) {
        user = await this.users.one({ email })
        if (user) {
          // Link existing user
          const primitives = user.toPrimitives()
          const updated = User.fromPrimitives({
            ...primitives,
            googleId:
              payload.provider === "google"
                ? socialId
                : primitives.googleId ?? null,
            appleId:
              payload.provider === "apple"
                ? socialId
                : primitives.appleId ?? null,
            updatedAt: new Date(),
          })
          await this.users.upsert(updated)
          user = updated
        }
      }

      // 4. Create New User
      if (!user) {
        if (!email) {
          return {
            error: "Email obrigatório para primeiro acesso",
            status: 400,
          }
        }

        const passwordHash = await argon2.hash(crypto.randomUUID()) // Random password

        user = User.create({
          email,
          name: payload.name ?? null,
          passwordHash,
          googleId: payload.provider === "google" ? socialId : null,
          appleId: payload.provider === "apple" ? socialId : null,
        })

        await this.users.upsert(user)
        await this.seedDefaultCategories(user.getUserId())
        await this.seedDefaultAccount(user.getUserId())
      }

      // 5. Login (Issue Tokens)
      const primitives = user.toPrimitives()
      const updatedLogin = User.fromPrimitives({
        ...primitives,
        lastLoginAt: new Date(),
      })
      await this.users.upsert(updatedLogin)

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
    } catch (e) {
      console.error(e)
      return { error: "Erro no login social", status: 500 }
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
  private async seedDefaultAccount(userId: string) {
    const account = Account.create({
      userId,
      name: "Carteira",
      type: AccountType.Wallet,
      bankType: null,
      currency: "BRL",
      isActive: true,
    })
    await this.accounts.upsert(account)
  }

  private async verifySocialToken(
    provider: "google" | "apple",
    token: string
  ): Promise<{ email?: string; socialId: string } | null> {
    try {
      if (provider === "google") {
        // GOOGLE
        // TODO: Move CLIENT_ID to .env or use generic verify
        // For now validating structure or using generic if library requires clientID
        const client = new OAuth2Client()
        const ticket = await client.verifyIdToken({
          idToken: token,
          // audience: env.GOOGLE_CLIENT_ID, // Specify if available
        })
        const payload = ticket.getPayload()
        if (!payload) return null
        return {
          email: payload.email,
          socialId: payload.sub,
        }
      } else {
        // APPLE
        const payload = await appleSignin.verifyIdToken(token, {
          // audience: env.APPLE_CLIENT_ID, // Client ID - if needed
          // ignoreExpiration: true, // Optional
        })
        if (!payload) return null
        return {
          email: payload.email,
          socialId: payload.sub,
        }
      }
    } catch (e) {
      console.error("Social Token Error:", e)
      return null
    }
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

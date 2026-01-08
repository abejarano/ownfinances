import crypto from "node:crypto";
import argon2 from "argon2";
import { User, UserPrimitives } from "../models/auth/user";
import { RefreshToken } from "../models/auth/refresh_token";
import type { UserMongoRepository } from "../repositories/user_mongo_repository";
import type { RefreshTokenMongoRepository } from "../repositories/refresh_token_mongo_repository";
import { env } from "../shared/env";

export class AuthService {
  constructor(
    private readonly users: UserMongoRepository,
    private readonly refreshTokens: RefreshTokenMongoRepository
  ) {}

  async register(payload: {
    email?: string;
    password?: string;
    name?: string;
  }) {
    const email = payload.email?.trim().toLowerCase();
    const password = payload.password;

    if (!email) return { error: "Email obrigatório" };
    if (!password) return { error: "Senha obrigatória" };

    const existing = await this.users.one({ email });
    if (existing) return { error: "Email já cadastrado" };

    const passwordHash = await argon2.hash(password);

    const user = User.create({
      email,
      name: payload.name ?? null,
      passwordHash,
    });

    await this.users.upsert(user);

    const refresh = await this.issueRefreshToken(user.getUserId());
    return {
      user: toUserResponse(user.toPrimitives()),
      userId: user.getUserId(),
      refreshToken: refresh.refreshToken,
    };
  }

  async login(payload: { email?: string; password?: string }) {
    const email = payload.email?.trim().toLowerCase();
    const password = payload.password;

    if (!email || !password) return { error: "Credenciais inválidas" };

    const user = await this.users.one({ email });
    if (!user) return { error: "Credenciais inválidas" };

    const userPrimitives = user.toPrimitives();
    const valid = await argon2.verify(userPrimitives.passwordHash, password);
    if (!valid) return { error: "Credenciais inválidas" };

    const updated: UserPrimitives = {
      ...userPrimitives,
      id: userPrimitives.id ?? userPrimitives.userId,
      lastLoginAt: new Date(),
      updatedAt: new Date(),
    };

    await this.users.upsert(User.fromPrimitives(updated));

    const refresh = await this.issueRefreshToken(user.getUserId());
    return {
      user: toUserResponse(updated),
      userId: user.getUserId(),
      refreshToken: refresh.refreshToken,
    };
  }

  async refresh(payload: {
    refreshToken?: string;
    userAgent?: string;
    ip?: string;
  }) {
    if (!payload.refreshToken) {
      return { error: "Sessão expirada, entre novamente" };
    }

    const tokenHash = hashToken(payload.refreshToken);
    const existing = await this.refreshTokens.one({ tokenHash });
    if (!existing) {
      return { error: "Sessão expirada, entre novamente" };
    }

    const existingPrimitives = existing.toPrimitives();
    if (existingPrimitives.revokedAt) {
      return { error: "Sessão expirada, entre novamente" };
    }

    if (existingPrimitives.expiresAt < new Date()) {
      return { error: "Sessão expirada, entre novamente" };
    }

    const revoked = RefreshToken.fromPrimitives({
      ...existingPrimitives,
      id: existingPrimitives.id ?? existingPrimitives.refreshTokenId,
      revokedAt: new Date(),
    });
    await this.refreshTokens.upsert(revoked);

    const refresh = await this.issueRefreshToken(
      existingPrimitives.userId,
      payload.userAgent,
      payload.ip
    );
    return {
      userId: existingPrimitives.userId,
      refreshToken: refresh.refreshToken,
    };
  }

  async logout(payload: { refreshToken?: string }) {
    if (!payload.refreshToken) {
      return { error: "Sessão expirada, entre novamente" };
    }

    const tokenHash = hashToken(payload.refreshToken);
    const existing = await this.refreshTokens.one({ tokenHash });
    if (!existing) {
      return { error: "Sessão expirada, entre novamente" };
    }

    const existingPrimitives = existing.toPrimitives();
    const revoked = RefreshToken.fromPrimitives({
      ...existingPrimitives,
      id: existingPrimitives.id ?? existingPrimitives.refreshTokenId,
      revokedAt: new Date(),
    });

    await this.refreshTokens.upsert(revoked);
    return { ok: true };
  }

  async getMe(userId: string) {
    const user = await this.users.one({ userId });
    if (!user) return { error: "Sessão expirada, entre novamente" };
    return { user: toUserResponse(user.toPrimitives()) };
  }

  private async issueRefreshToken(
    userId: string,
    userAgent?: string,
    ip?: string
  ) {
    const refreshToken = generateRefreshToken();
    const now = new Date();
    const refreshTtlDays = env.REFRESH_TOKEN_TTL;
    const expiresAt = new Date(
      now.getTime() + refreshTtlDays * 24 * 60 * 60 * 1000
    );

    const refreshEntity = RefreshToken.create({
      userId,
      tokenHash: hashToken(refreshToken),
      expiresAt,
      userAgent: userAgent ?? null,
      ip: ip ?? null,
    });

    await this.refreshTokens.upsert(refreshEntity);

    return {
      refreshToken,
    };
  }
}

function hashToken(token: string) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function generateRefreshToken() {
  return crypto.randomBytes(48).toString("base64url");
}

function toUserResponse(user: UserPrimitives) {
  return {
    id: user.userId,
    email: user.email,
    name: user.name ?? null,
  };
}

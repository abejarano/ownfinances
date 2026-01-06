import { ObjectId } from "mongodb";
import crypto from "node:crypto";
import argon2 from "argon2";
import { User, UserPrimitives } from "../../domain/auth/user";
import { RefreshToken } from "../../domain/auth/refresh_token";
import type { UserMongoRepository } from "../../infrastructure/repositories/user_mongo_repository";
import type { RefreshTokenMongoRepository } from "../../infrastructure/repositories/refresh_token_mongo_repository";
import { env } from "../../shared/env";

export class AuthService {
  constructor(
    private readonly users: UserMongoRepository,
    private readonly refreshTokens: RefreshTokenMongoRepository,
  ) {}

  async register(payload: { email?: string; password?: string; name?: string }) {
    const email = payload.email?.trim().toLowerCase();
    const password = payload.password;

    if (!email) return { error: "Email requerido" };
    if (!password) return { error: "Password requerido" };

    await this.users.ensureIndexes();
    const existing = await this.users.findByEmail(email);
    if (existing) return { error: "Email ya registrado" };

    const now = new Date();
    const newId = new ObjectId().toHexString();
    const passwordHash = await argon2.hash(password);

    const user = new User({
      id: newId,
      userId: newId,
      email,
      name: payload.name ?? null,
      passwordHash,
      createdAt: now,
      updatedAt: now,
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

    if (!email || !password) return { error: "Credenciales inválidas" };

    const user = await this.users.findByEmail(email);
    if (!user) return { error: "Credenciales inválidas" };

    const valid = await argon2.verify(user.passwordHash, password);
    if (!valid) return { error: "Credenciales inválidas" };

    const updated: UserPrimitives = {
      ...user,
      id: user.id ?? user.userId,
      lastLoginAt: new Date(),
      updatedAt: new Date(),
    };

    await this.users.upsert(User.fromPrimitives(updated));

    const refresh = await this.issueRefreshToken(user.userId);
    return {
      user: toUserResponse(updated),
      userId: user.userId,
      refreshToken: refresh.refreshToken,
    };
  }

  async refresh(payload: { refreshToken?: string; userAgent?: string; ip?: string }) {
    if (!payload.refreshToken) {
      return { error: "Sesión expirada, entra de nuevo" };
    }

    const tokenHash = hashToken(payload.refreshToken);
    const existing = await this.refreshTokens.one({ tokenHash });
    if (!existing || existing.revokedAt) {
      return { error: "Sesión expirada, entra de nuevo" };
    }

    if (existing.expiresAt < new Date()) {
      return { error: "Sesión expirada, entra de nuevo" };
    }

    const revoked = RefreshToken.fromPrimitives({
      ...existing,
      id: existing.id ?? existing.refreshTokenId,
      revokedAt: new Date(),
    });
    await this.refreshTokens.upsert(revoked);

    const refresh = await this.issueRefreshToken(existing.userId, payload.userAgent, payload.ip);
    return {
      userId: existing.userId,
      refreshToken: refresh.refreshToken,
    };
  }

  async logout(payload: { refreshToken?: string }) {
    if (!payload.refreshToken) {
      return { error: "Sesión expirada, entra de nuevo" };
    }

    const tokenHash = hashToken(payload.refreshToken);
    const existing = await this.refreshTokens.one({ tokenHash });
    if (!existing) {
      return { error: "Sesión expirada, entra de nuevo" };
    }

    const revoked = RefreshToken.fromPrimitives({
      ...existing,
      id: existing.id ?? existing.refreshTokenId,
      revokedAt: new Date(),
    });

    await this.refreshTokens.upsert(revoked);
    return { ok: true };
  }

  async getMe(userId: string) {
    const user = await this.users.one({ userId });
    if (!user) return { error: "Sesión expirada, entra de nuevo" };
    return { user: toUserResponse(user) };
  }

  private async issueRefreshToken(userId: string, userAgent?: string, ip?: string) {
    const refreshToken = generateRefreshToken();
    const now = new Date();
    const refreshTtlDays = env.REFRESH_TOKEN_TTL;
    const expiresAt = new Date(now.getTime() + refreshTtlDays * 24 * 60 * 60 * 1000);
    const refreshId = new ObjectId().toHexString();

    const refreshEntity = new RefreshToken({
      id: refreshId,
      refreshTokenId: refreshId,
      userId,
      tokenHash: hashToken(refreshToken),
      createdAt: now,
      expiresAt,
      revokedAt: null,
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

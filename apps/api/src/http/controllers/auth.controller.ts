import type { AuthService } from "../../services/auth_service";
import { badRequest, unauthorized } from "../errors";
import { env } from "../../shared/env";
import type {
  AuthLoginPayload,
  AuthLogoutPayload,
  AuthRefreshPayload,
  AuthRegisterPayload,
} from "../validation/auth.validation";

export class AuthController {
  constructor(private readonly authService: AuthService) {}

  async register({
    body,
    set,
    jwt,
  }: {
    body: AuthRegisterPayload;
    set: { status: number };
    jwt: any;
  }) {
    const result = await this.authService.register(body);
    if ("error" in result) return badRequest(set, result.error ?? "Error");
    const accessToken = await jwt.sign({
      sub: result.userId,
      exp: env.ACCESS_TOKEN_TTL,
    });
    return {
      user: result.user,
      accessToken,
      refreshToken: result.refreshToken,
    };
  }

  async login({
    body,
    set,
    jwt,
  }: {
    body: AuthLoginPayload;
    set: { status: number };
    jwt: any;
  }) {
    const result = await this.authService.login(body);
    if ("error" in result) return badRequest(set, result.error ?? "Error");
    const accessToken = await jwt.sign({
      sub: result.userId,
      exp: env.ACCESS_TOKEN_TTL,
    });
    return {
      user: result.user,
      accessToken,
      refreshToken: result.refreshToken,
    };
  }

  async refresh({
    body,
    headers,
    set,
    jwt,
  }: {
    body: AuthRefreshPayload;
    headers: Record<string, string | undefined>;
    set: { status: number };
    jwt: any;
  }) {
    const result = await this.authService.refresh({
      refreshToken: body.refreshToken,
      userAgent: headers["user-agent"],
      ip: headers["x-forwarded-for"] ?? headers["x-real-ip"],
    });
    if ("error" in result) return badRequest(set, result.error ?? "Error");
    const accessToken = await jwt.sign({
      sub: result.userId,
      exp: env.ACCESS_TOKEN_TTL,
    });
    return {
      accessToken,
      refreshToken: result.refreshToken,
    };
  }

  async logout({
    body,
    set,
  }: {
    body: AuthLogoutPayload;
    set: { status: number };
  }) {
    const result = await this.authService.logout({
      refreshToken: body.refreshToken,
    });
    if ("error" in result) return badRequest(set, result.error ?? "Error");
    return result;
  }

  async me({ userId, set }: { userId?: string; set: { status: number } }) {
    if (!userId) {
      return unauthorized(set, "Sesión expirada, entra de nuevo");
    }
    const result = await this.authService.getMe(userId);
    if (result.error) return unauthorized(set, result.error);
    return result.user;
  }
}

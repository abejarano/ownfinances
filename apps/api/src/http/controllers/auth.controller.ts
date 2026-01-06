import type { AuthService } from "../../application/services/auth.service";
import { badRequest, unauthorized } from "../errors";
import { env } from "../../shared/env";

export class AuthController {
  constructor(private readonly authService: AuthService) {}

  register = async ({ body, set, jwt }: { body: unknown; set: { status: number }; jwt: any }) => {
    const result = await this.authService.register(body as Record<string, unknown>);
    if ("error" in result) return badRequest(set, result.error ?? "Error");
    const accessToken = await jwt.sign({ sub: result.userId, exp: env.ACCESS_TOKEN_TTL });
    return {
      user: result.user,
      accessToken,
      refreshToken: result.refreshToken,
    };
  };

  login = async ({ body, set, jwt }: { body: unknown; set: { status: number }; jwt: any }) => {
    const result = await this.authService.login(body as Record<string, unknown>);
    if ("error" in result) return badRequest(set, result.error ?? "Error");
    const accessToken = await jwt.sign({ sub: result.userId, exp: env.ACCESS_TOKEN_TTL });
    return {
      user: result.user,
      accessToken,
      refreshToken: result.refreshToken,
    };
  };

  refresh = async ({ body, headers, set, jwt }: { body: unknown; headers: Record<string, string | undefined>; set: { status: number }; jwt: any }) => {
    const payload = body as Record<string, unknown>;
    const result = await this.authService.refresh({
      refreshToken: payload.refreshToken as string | undefined,
      userAgent: headers["user-agent"],
      ip: headers["x-forwarded-for"] ?? headers["x-real-ip"],
    });
    if ("error" in result) return badRequest(set, result.error ?? "Error");
    const accessToken = await jwt.sign({ sub: result.userId, exp: env.ACCESS_TOKEN_TTL });
    return {
      accessToken,
      refreshToken: result.refreshToken,
    };
  };

  logout = async ({ body, set }: { body: unknown; set: { status: number } }) => {
    const payload = body as Record<string, unknown>;
    const result = await this.authService.logout({
      refreshToken: payload.refreshToken as string | undefined,
    });
    if ("error" in result) return badRequest(set, result.error ?? "Error");
    return result;
  };

  me = async ({ userId, set }: { userId?: string; set: { status: number } }) => {
    if (!userId) {
      return unauthorized(set, "Sesión expirada, entra de nuevo");
    }
    const result = await this.authService.getMe(userId);
    if (result.error) return unauthorized(set, result.error);
    return result.user;
  };
}

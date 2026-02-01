import {
  Body,
  Controller,
  Post,
  Req,
  Res,
  type ServerRequest,
  type ServerResponse,
  Use,
} from "bun-platform-kit"
import { SignJWT } from "jose"
import { Deps } from "../../bootstrap/deps"
import { env } from "../../bootstrap/env.ts"
import { HttpResponse } from "../../bootstrap/response"
import type { AuthService } from "../../services/auth_service"
import {
  type AuthLoginPayload,
  type AuthLogoutPayload,
  type AuthRefreshPayload,
  type AuthRegisterPayload,
  type AuthSocialLoginPayload,
  validateAuthLoginPayload,
  validateAuthLogoutPayload,
  validateAuthRefreshPayload,
  validateAuthRegisterPayload,
  validateAuthSocialLoginPayload,
} from "../validation/auth.validation"

@Controller("/auth")
export class AuthController {
  private authService: AuthService

  constructor() {
    const deps = Deps.getInstance()
    this.authService = deps.authService
  }

  @Post("/social-login")
  @Use(validateAuthSocialLoginPayload)
  async socialLogin(
    @Body() body: AuthSocialLoginPayload,
    @Req() req: ServerRequest,
    @Res() res: ServerResponse
  ) {
    try {
      const result = await this.authService.socialLogin(body)

      if (result.error) {
        return HttpResponse(res, result)
      }

      const secretKey = new TextEncoder().encode(env.JWT_SECRET)

      const accessToken = await new SignJWT({})
        .setSubject(result.value!.user.userId)
        .setExpirationTime(env.ACCESS_TOKEN_TTL)
        .setProtectedHeader({ alg: "HS256" })
        .sign(secretKey)

      return res.status(200).json({
        user: result.value!.user,
        accessToken,
        refreshToken: result.value!.refreshToken,
      })
    } catch (e) {
      console.log(e)
      HttpResponse(res, { error: "Error internal Server", status: 500 })
    }
  }

  @Post("/login")
  @Use(validateAuthLoginPayload)
  async login(
    @Body() body: AuthLoginPayload,
    @Req() req: ServerRequest,
    @Res() res: ServerResponse
  ) {
    try {
      const result = await this.authService.login(body)

      if (result.error) {
        return HttpResponse(res, result)
      }

      const secretKey = new TextEncoder().encode(env.JWT_SECRET)

      const accessToken = await new SignJWT({})
        .setSubject(result.value!.user.userId)
        .setExpirationTime(env.ACCESS_TOKEN_TTL) // e.g. "15m" o timestamp en segundos
        .setProtectedHeader({ alg: "HS256" })
        .sign(secretKey)

      return res.status(200).json({
        user: result.value!.user,
        accessToken,
        refreshToken: result.value!.refreshToken,
      })
    } catch (e) {
      console.log(e)
      HttpResponse(res, { error: "Error internal Server", status: 500 })
    }
  }

  @Post("/register")
  @Use(validateAuthRegisterPayload)
  async register(
    @Body() body: AuthRegisterPayload,
    @Req() req: ServerRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.authService.register(body)
    if (result.error) {
      return HttpResponse(res, result)
    }

    const secretKey = new TextEncoder().encode(env.JWT_SECRET)

    const accessToken = await new SignJWT({})
      .setSubject(result.value!.user.userId)
      .setExpirationTime(env.ACCESS_TOKEN_TTL) // e.g. "15m" o timestamp en segundos
      .setProtectedHeader({ alg: "HS256" })
      .sign(secretKey)

    return res.status(201).json({
      user: result.value!.user,
      accessToken,
      refreshToken: result.value!.refreshToken,
    })
  }

  @Post("/refresh")
  @Use(validateAuthRefreshPayload)
  async refresh(
    @Body() body: AuthRefreshPayload,
    @Req() req: ServerRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.authService.refresh({
      refreshToken: body.refreshToken,
      userAgent: req.headers["user-agent"] as string | undefined,
      ip: req.ip,
    })

    if (result.error) {
      return HttpResponse(res, result)
    }

    const secretKey = new TextEncoder().encode(env.JWT_SECRET)

    const accessToken = await new SignJWT({})
      .setSubject(result.value!.userId)
      .setExpirationTime(env.ACCESS_TOKEN_TTL) // e.g. "15m" o timestamp en segundos
      .setProtectedHeader({ alg: "HS256" })
      .sign(secretKey)

    return res.status(201).json({
      accessToken,
      refreshToken: result.value!.refreshToken,
    })
  }

  @Post("/logout")
  @Use(validateAuthLogoutPayload)
  async logout(
    @Body() body: AuthLogoutPayload,
    @Req() req: ServerRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.authService.logout({
      refreshToken: body.refreshToken,
    })

    return HttpResponse(res, result)
  }

  @Post("/me")
  async me(
    @Body() body: { userId: string },
    @Req() req: ServerRequest,
    @Res() res: ServerResponse
  ) {
    if (!body.userId) {
      return HttpResponse(res, {
        error: "Sessão expirada, entre novamente",
        status: 403,
      })
    }

    const result = await this.authService.getMe(body.userId)

    return HttpResponse(res, result)
  }
}

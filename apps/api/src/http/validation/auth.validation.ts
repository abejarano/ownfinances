import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "bun-platform-kit"
import * as v from "valibot"
import { HttpResponse } from "../../bootstrap/response"

export type AuthRegisterPayload = {
  email: string
  password: string
  name?: string
}

export type AuthLoginPayload = {
  email: string
  password: string
}

export type AuthRefreshPayload = {
  refreshToken: string
}

export type AuthLogoutPayload = {
  refreshToken: string
}

export type AuthSocialLoginPayload = {
  provider: "google" | "apple"
  token: string
  email?: string
  name?: string
  socialId?: string
}

const RegisterSchema = v.strictObject({
  email: v.pipe(v.string(), v.minLength(1)),
  password: v.pipe(v.string(), v.minLength(1)),
  name: v.optional(v.pipe(v.string(), v.minLength(1))),
})

const LoginSchema = v.strictObject({
  email: v.pipe(v.string(), v.minLength(1)),
  password: v.pipe(v.string(), v.minLength(1)),
})

const RefreshSchema = v.strictObject({
  refreshToken: v.pipe(v.string(), v.minLength(1)),
})

const LogoutSchema = RefreshSchema

const SocialLoginSchema = v.strictObject({
  provider: v.picklist(["google", "apple"]),
  token: v.pipe(v.string(), v.minLength(1)),
  email: v.optional(v.string()),
  name: v.optional(v.string()),
  socialId: v.optional(v.string()),
})

export function validateAuthSocialLoginPayload(
  req: ServerRequest,
  res: ServerResponse,
  next: NextFunction
) {
  const payload = req.body as AuthSocialLoginPayload

  const result = v.safeParse(SocialLoginSchema, payload)
  if (result.success) return next()

  if (!result.issues) return res.status(422).send({ error: "Payload invalido" })
  const flattened = v.flatten(result.issues)

  if (flattened.nested?.provider)
    return res.status(422).send({ error: "Provedor inválido (google ou apple)" })
  if (flattened.nested?.token) return res.status(422).send({ error: "Token obrigatório" })

  return res.status(422).send({ error: "Payload invalido" })
}

export function validateAuthRegisterPayload(
  req: ServerRequest,
  res: ServerResponse,
  next: NextFunction
) {
  const payload = req.body as AuthRegisterPayload

  const result = v.safeParse(RegisterSchema, payload)
  if (result.success) return next()

  if (!result.issues) return res.status(422).send({ error: "Payload invalido" })
  const flattened = v.flatten(result.issues)
  if (flattened.nested?.email) return res.status(422).send({ error: "Email obrigatório" })
  if (flattened.nested?.password)
    return res.status(422).send({ error: "Senha obrigatória" })
  if (flattened.nested?.name) return res.status(422).send({ error: "Nome invalido" })

  return res.status(422).send({ error: "Payload invalido" })
}

export function validateAuthLoginPayload(
  req: ServerRequest,
  res: ServerResponse,
  next: NextFunction
) {
  try {
    const payload = req.body as AuthLoginPayload

    const result = v.safeParse(LoginSchema, payload)
    if (result.success) return next()

    if (!result.issues) return res.status(422).send({ error: "Payload invalido" })
    const flattened = v.flatten(result.issues)

    if (flattened.nested?.email) return res.status(422).send({ error: "Informe o E-mail" })

    if (flattened.nested?.password)
      return res.status(422).send({ error: "Informe a senha" })

    return res.status(422).send({ error: "Payload invalido" })
  } catch (e) {
    console.log(`errrr ${e}`)
    return HttpResponse(res, { error: "Error interno", status: 500 })
  }
}

export function validateAuthRefreshPayload(
  req: ServerRequest,
  res: ServerResponse,
  next: NextFunction
) {
  const payload = req.body as AuthRefreshPayload

  const result = v.safeParse(RefreshSchema, payload)
  if (result.success) return next()

  if (!result.issues) return res.status(422).send({ error: "Payload invalido" })

  const flattened = v.flatten(result.issues)
  if (flattened.nested?.refreshToken)
    return res.status(422).send({ error: "Sessão expirada, entre novamente" })

  return res.status(422).send({ error: "Payload invalido" })
}

export function validateAuthLogoutPayload(
  req: ServerRequest,
  res: ServerResponse,
  next: NextFunction
) {
  const payload = req.body as AuthLogoutPayload

  const result = v.safeParse(LogoutSchema, payload)
  if (result.success) {
    return next()
  }

  if (!result.issues) return res.status(422).send({ error: "Payload invalido" })

  const flattened = v.flatten(result.issues)
  if (flattened.nested?.refreshToken)
    return res.status(422).send({ error: "Sessão expirada, entre novamente" })

  return res.status(422).send({ error: "Payload invalido" })
}

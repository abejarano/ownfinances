import type {
  NextFunction,
  ServerRequest,
  ServerResponse,
} from "bun-platform-kit"
import { jwtVerify } from "jose"
import { env } from "../../shared/env"

const encoder = new TextEncoder()

export const AuthMiddleware = async (
  req: ServerRequest,
  res: ServerResponse,
  next: NextFunction
) => {
  const jwtSecret = env.JWT_SECRET
  const authHeader = req.headers?.authorization as string

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).send("Sessão expirada, entre novamente")
  }

  if (!jwtSecret) {
    return res.status(500).send("JWT secret no configurado")
  }

  const token = authHeader.replace("Bearer ", "").trim()
  try {
    const { payload } = await jwtVerify(token, encoder.encode(jwtSecret))
    if (!payload.sub) {
      return res.status(401).send("Sessão expirada, entre novamente")
    }

    ;(req as { userId?: string }).userId = payload.sub
    return next()
  } catch (_) {
    return res.status(401).send("Sessão expirada, entre novamente")
  }
}

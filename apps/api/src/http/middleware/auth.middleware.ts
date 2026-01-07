import { unauthorized as unauthorizedResponse } from "../errors";

export type AuthContext = {
  headers: Record<string, string | undefined>;
  set: { status: number };
  jwt?: { verify(token?: string): Promise<any | false> };
  userId?: string;
};

export async function requireAuth(ctx: AuthContext) {
  const authHeader = ctx.headers?.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return respondUnauthorized(ctx);
  }

  const token = authHeader.replace("Bearer ", "").trim();
  try {
    if (!ctx.jwt) {
      return respondUnauthorized(ctx);
    }
    const decoded = await ctx.jwt.verify(token);
    if (!decoded || typeof decoded !== "object" || !("sub" in decoded)) {
      return respondUnauthorized(ctx);
    }
    ctx.userId = (decoded as { sub?: string }).sub;
    return null;
  } catch (_) {
    return respondUnauthorized(ctx);
  }
}

function respondUnauthorized(ctx: AuthContext) {
  return unauthorizedResponse(ctx.set, "Sessão expirada, entre novamente");
}

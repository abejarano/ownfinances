export const env = {
  PORT: Number(Bun.env.PORT ?? 3000),
  NODE_ENV: Bun.env.NODE_ENV ?? "development",
  JWT_SECRET:
    Bun.env.JWT_SECRET ??
    "8137daa815be69d333da7336e19010c1149cd32b53d6a2b217593ae35bddaae3",
  ACCESS_TOKEN_TTL: Bun.env.ACCESS_TOKEN_TTL ?? "45m",
  REFRESH_TOKEN_TTL: Number(Bun.env.REFRESH_TOKEN_TTL ?? 30),
  MAX_BODY_SIZE: Number(Bun.env.UPLOAD_MAX_BODY_BYTES ?? 25 * 1024 * 1024),
  MAX_FILE_SIZE: Number(Bun.env.UPLOAD_MAX_FILE_BYTES ?? 25 * 1024 * 1024),

  BULL_USER: Bun.env.BULL_USER ?? "user",
  BULL_PASSWORD: Bun.env.BULL_PASSWORD ?? "password",
}

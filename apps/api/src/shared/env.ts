export const env = {
  MONGODB_URI: Bun.env.MONGODB_URI ?? "mongodb://localhost:27017",
  DB_NAME: Bun.env.DB_NAME ?? "ownfinances",
  USER_ID_DEFAULT: Bun.env.USER_ID_DEFAULT ?? "user_demo",
  PORT: Number(Bun.env.PORT ?? 3000),
  NODE_ENV: Bun.env.NODE_ENV ?? "development",
  JWT_SECRET:
    Bun.env.JWT_SECRET ??
    "8137daa815be69d333da7336e19010c1149cd32b53d6a2b217593ae35bddaae3",
  ACCESS_TOKEN_TTL: Bun.env.ACCESS_TOKEN_TTL ?? "45m",
  REFRESH_TOKEN_TTL: Number(Bun.env.REFRESH_TOKEN_TTL ?? 30),
}

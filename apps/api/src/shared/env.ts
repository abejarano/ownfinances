export const env = {
  MONGODB_URI: process.env.MONGODB_URI ?? "mongodb://localhost:27017",
  DB_NAME: process.env.DB_NAME ?? "ownfinances",
  USER_ID_DEFAULT: process.env.USER_ID_DEFAULT ?? "user_demo",
  PORT: Number(process.env.PORT ?? 3000),
  NODE_ENV: process.env.NODE_ENV ?? "development",
  JWT_SECRET: process.env.JWT_SECRET ?? "dev-secret",
  ACCESS_TOKEN_TTL: process.env.ACCESS_TOKEN_TTL ?? "15m",
  REFRESH_TOKEN_TTL: Number(process.env.REFRESH_TOKEN_TTL ?? 30),
};

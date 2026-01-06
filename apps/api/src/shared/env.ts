export const env = {
  MONGODB_URI: process.env.MONGODB_URI ?? "mongodb://localhost:27017",
  DB_NAME: process.env.DB_NAME ?? "ownfinances",
  USER_ID_DEFAULT: process.env.USER_ID_DEFAULT ?? "user_demo",
  PORT: Number(process.env.PORT ?? 3000),
  NODE_ENV: process.env.NODE_ENV ?? "development",
};

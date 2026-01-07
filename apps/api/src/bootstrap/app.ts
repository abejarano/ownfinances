import { Elysia } from "elysia";
import { openapi } from "@elysiajs/openapi";
import { jwt } from "@elysiajs/jwt";
import { cors } from "@elysiajs/cors";
import pkg from "../../package.json";
import { env } from "../shared/env";
import { registerRoutes } from "../http/routes";
import type { AppDeps } from "./deps";
import { getMongoClient } from "./mongo";

export function buildApp(deps: AppDeps) {
  const app = new Elysia()
    .use(
      cors({
        origin: true,
        allowedHeaders: ["Content-Type", "Authorization"],
        methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      }),
    )
    .use(openapi())
    .use(
      jwt({
        name: "jwt",
        secret: env.JWT_SECRET,
      }),
    )
    .get("/health", async () => {
      const client = await getMongoClient();
      const ping = await client.db().command({ ping: 1 });
      return { ok: true, ping };
    })
    .get("/meta", () => ({
      name: pkg.name,
      version: pkg.version,
      env: env.NODE_ENV,
    }));

  registerRoutes(app, deps);

  return app;
}

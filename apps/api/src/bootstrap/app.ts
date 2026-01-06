import { Elysia } from "elysia";
import { openapi } from "@elysiajs/openapi";
import pkg from "../../package.json";
import { env } from "../shared/env";
import { registerRoutes } from "../http/routes";
import type { AppDeps } from "./deps";
import { getMongoClient } from "./mongo";

export function buildApp(deps: AppDeps) {
  const app = new Elysia()
    .use(openapi())
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

  registerRoutes(app, deps, env.USER_ID_DEFAULT);

  return app;
}

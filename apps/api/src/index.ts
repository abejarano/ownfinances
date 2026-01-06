import { env } from "./shared/env";
import { closeMongoClient } from "./bootstrap/mongo";
import { buildDeps } from "./bootstrap/deps";
import { buildApp } from "./bootstrap/app";
import { seedDevData } from "./dev/seed";

const deps = buildDeps();

if (env.NODE_ENV !== "production") {
  await seedDevData(env.USER_ID_DEFAULT, deps.categoryRepo, deps.accountRepo);
}

const app = buildApp(deps).listen(env.PORT);

console.log(`API running at http://localhost:${app.server?.port}`);

process.on("SIGINT", async () => {
  await closeMongoClient();
  process.exit(0);
});

process.on("SIGTERM", async () => {
  await closeMongoClient();
  process.exit(0);
});

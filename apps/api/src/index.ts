import {
  BunKitServer,
  CorsModule,
  FileUploadModule,
  SecurityModule,
} from "bun-platform-kit"
import { controllersModule } from "./bootstrap/controllers"
import { env } from "./bootstrap/env.ts"

import { QueueName, StartQueueService } from "@desquadra/queue"
import { BankingCouncil } from "./jobs/banking.council.job.ts"

const server = new BunKitServer(Number(env.PORT))

server.addModules([
  new CorsModule({
    allowedHeaders: ["content-type", "authorization"],
  }),
  new SecurityModule(),
  controllersModule(),
  new FileUploadModule({
    allowedMimeTypes: [
      "text/csv",
      "application/csv",
      "application/vnd.ms-excel",
    ],
    maxBodyBytes: env.MAX_BODY_SIZE,
    maxFileBytes: env.MAX_FILE_SIZE,
  }),
])

await StartQueueService({
  credentials: {
    user: env.BULL_USER,
    password: env.BULL_PASSWORD,
  },
  app: server.getApp(),
  listQueues: [
    {
      name: QueueName.CategorizeTransactions,
    },
    {
      name: QueueName.BankingCouncil,
      useClass: BankingCouncil,
    },
  ],
})

server.start()

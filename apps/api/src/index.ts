import {
  BunKitServer,
  CorsModule,
  FileUploadModule,
  SecurityModule,
} from "bun-platform-kit"
import { controllersModule } from "./bootstrap/controllers"
import { env } from "./shared/env"

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
    maxBodyBytes: Number(process.env.UPLOAD_MAX_BODY_BYTES ?? 25 * 1024 * 1024),
    maxFileBytes: Number(process.env.UPLOAD_MAX_FILE_BYTES ?? 25 * 1024 * 1024),
  }),
])

await StartQueueService({
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

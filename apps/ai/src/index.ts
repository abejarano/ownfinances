import { QueueName, StartQueueService } from "@desquadra/queue";

import { CategoryMongoRepository } from "@desquadra/database";
import { CategorizeTransactions } from "./categorizerTransaccions.job.ts";
import { env } from "./config";

StartQueueService({
  credentials: {
    user: env.BULL_USER,
    password: env.BULL_PASSWORD,
  },
  listQueues: [
    {
      name: QueueName.BankingCouncil,
    },
    {
      name: QueueName.CategorizeTransactions,
      useClass: CategorizeTransactions,
      inject: [CategoryMongoRepository.getInstance()],
    },
  ],
});

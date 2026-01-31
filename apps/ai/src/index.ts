import { QueueName, StartQueueService } from "@desquadra/queue";

import { CategoryMongoRepository } from "@desquadra/database";
import { CategorizeTransactions } from "./categorizerTransaccions.job.ts";

StartQueueService({
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

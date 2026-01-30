import { QueueName, StartQueueService } from "@desquadra/queue";

import { CategoryMongoRepository } from "@desquadra/database";
import { CategorizerTransactionsJob } from "./categorizerTransaccions.job.ts";

StartQueueService({
  runProcessing: true,
  listQueues: [
    {
      name: QueueName.CategorizeTransactions,
      useClass: CategorizerTransactionsJob,
      inject: [CategoryMongoRepository.getInstance()],
    },
  ],
});

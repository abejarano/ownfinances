import { QueueName, StartQueueService } from "@desquadra/queue";

import { CategoryMongoRepository } from "@desquadra/database";
import { CategorizerTransactions } from "./categorizerTransaccions.job.ts";

StartQueueService({
  runProcessing: true,
  listQueues: [
    {
      name: QueueName.CategorizeTransactions,
      useClass: CategorizerTransactions,
      inject: [CategoryMongoRepository.getInstance()],
    },
  ],
});

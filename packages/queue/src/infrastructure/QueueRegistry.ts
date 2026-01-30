import Queue from "bull";
import { IListQueue, QueueName } from "../domain";

export class QueueRegistry {
  private static instance: QueueRegistry;
  private queueInstances: Map<string, Queue.Queue> = new Map();
  private queueDefinitions: Map<string, IListQueue> = new Map();

  private redisConfig = {
    host: process.env.REDIS_HOST,
    port: parseInt(process.env.REDIS_PORT || "6379"),
    username: process.env.REDIS_USER,
    password: process.env.REDIS_PASSWORD,
  };

  private constructor() {}

  static getInstance(): QueueRegistry {
    if (!QueueRegistry.instance) {
      QueueRegistry.instance = new QueueRegistry();
    }
    return QueueRegistry.instance;
  }

  registerQueueDefinitions(definitions: IListQueue[]): void {
    console.log(`Registering ${definitions.length} queue definitions`);

    definitions.forEach((definition) => {
      const queueName = definition.name || definition.useClass?.name;

      if (!queueName) {
        throw new Error(
          "Queue definition must have either 'name' or 'useClass' property",
        );
      }

      this.queueDefinitions.set(queueName, definition);
    });
  }

  async initializeQueues(): Promise<void> {
    console.log("Initializing all registered queues");

    for (const [queueName, definition] of this.queueDefinitions.entries()) {
      if (this.queueInstances.has(queueName)) {
        console.error(`Queue ${queueName} already initialized, skipping`);
        continue;
      }

      try {
        const queue = new Queue(queueName, {
          redis: this.redisConfig,
          defaultJobOptions: {
            delay: definition.delay ? definition.delay * 1000 : 0,
            removeOnComplete: true,
            removeOnFail: false,
          },
        });

        // Configurar manejo de eventos
        queue.on("ready", () =>
          console.log(`Queue ${queueName} connected to Redis`),
        );
        queue.on("error", (error) =>
          console.error(`Queue ${queueName} error:`, error),
        );

        // Verificación importante: asegurarse que la cola esté activa
        await queue.isReady();

        // Algunas colas pueden iniciar en estado pausado, asegurarse de que estén activas
        const isPaused = await queue.isPaused();
        if (isPaused) {
          await queue.resume();
        }

        this.queueInstances.set(queueName, queue);
      } catch (error) {
        console.error(`Error initializing queue ${queueName}:`, error);
      }
    }
  }

  getQueue(queueName: string): Queue.Queue | undefined {
    return this.queueInstances.get(queueName);
  }

  getQueueDefinition(queueName: string): IListQueue | undefined {
    return this.queueDefinitions.get(queueName);
  }

  getAllQueues(): Queue.Queue[] {
    return Array.from(this.queueInstances.values());
  }

  async shutdown(): Promise<void> {
    console.log("Shutting down all queues");

    const closePromises = Array.from(this.queueInstances.entries()).map(
      async ([queueName, queue]) => {
        try {
          console.log(`Closing queue ${queueName}`);
          queue.removeAllListeners();
          await queue.close();
          console.log(`Queue ${queueName} closed successfully`);
        } catch (error) {
          console.error(`Error closing queue ${queueName}:`, error);
        }
      },
    );

    await Promise.all(closePromises);
    this.queueInstances.clear();
    console.log("All queues shut down successfully");
  }
}

import { QueueName } from "../domain";
import { QueueRegistry } from "./QueueRegistry";
import { RequestContext } from "@abejarano/ts-express-server";
export class QueueProcessor {
  private static instance: QueueProcessor;
  private initialized: Set<string> = new Set();
  private registry: QueueRegistry;

  private constructor() {
    this.registry = QueueRegistry.getInstance();
  }

  static getInstance(): QueueProcessor {
    if (!QueueProcessor.instance) {
      QueueProcessor.instance = new QueueProcessor();
    }
    return QueueProcessor.instance;
  }

  /**
   * Inicia el procesamiento de todas las colas
   */
  async startProcessing(): Promise<void> {
    for (const queue of this.registry.getAllQueues()) {
      this.initializeQueueProcessor(queue.name);

      // Verificar que la cola no esté pausada
      const isPaused = await queue.isPaused();
      if (isPaused) {
        console.log(`Queue ${queue.name} is paused, resuming...`);
        await queue.resume();
      }
    }
  }

  /**
   * Pausa el procesamiento de todas las colas
   */
  async pauseProcessing(): Promise<void> {
    console.log("Pausing processing for all queues");

    const pausePromises = this.registry.getAllQueues().map(async (queue) => {
      try {
        await queue.pause();
        console.log(`Queue ${queue.name} paused`);
      } catch (error) {
        console.error(`Error pausing queue ${queue.name}:`, error);
      }
    });

    await Promise.all(pausePromises);
    console.log("All queues paused");
  }

  /**
   * Inicializa el procesador para una cola específica
   */
  private initializeQueueProcessor(queueName: string): void {
    // Evitar inicializar el mismo procesador varias veces
    if (this.initialized.has(queueName)) {
      console.log(`Processor for ${queueName} already initialized`);
      return;
    }

    const queue = this.registry.getQueue(queueName);
    const definition = this.registry.getQueueDefinition(queueName);

    if (!queue || !definition) {
      console.error(
        `Cannot initialize processor for ${queueName}: queue or definition not found`,
      );
      return;
    }

    if (!definition.useClass) {
      console.warn(
        `Cannot initialize processor for ${queueName}: useClass not defined`,
      );
      return;
    }

    // Crear la instancia del worker
    const workerInstance = definition.inject
      ? new definition.useClass(...definition.inject)
      : new definition.useClass();

    // Configurar el procesamiento de trabajos
    queue.process(async (job, done) => {
      const requestId = job.data?.requestId || `job-${job.id}`;

      RequestContext.run({ requestId }, async () => {
        try {
          await workerInstance.handle(job.data);
          done();
        } catch (error: any) {
          console.error(
            `Error processing job ${job.id} in queue ${queueName}:`,
            error,
          );
          done(error);
        }
      });
    });

    // Configurar listeners para eventos de la cola
    this.configureQueueListeners(queue);

    this.initialized.add(queueName);
    console.log(`Processor for ${queueName} initialized successfully`);
  }

  /**
   * Configura los listeners para eventos de la cola
   */
  private configureQueueListeners(queue: any): void {
    // Remover listeners existentes para evitar duplicados
    queue.removeAllListeners("failed");
    queue.removeAllListeners("completed");

    // Configurar nuevo listener para trabajos fallidos
    queue.on("failed", (job: any, error: any) => {
      const requestId = job.data?.requestId || `job-${job.id}`;

      RequestContext.run({ requestId }, async () => {
        console.error(`Job ${job.id} in queue ${queue.name} failed:`, error);

        // Evitar ciclos recursivos en notificaciones de error
        // if (queue.name !== QueueName.TelegramNotificationJob) {
        //   const queueDispatcher = QueueDispatcher.getInstance();
        //   queueDispatcher.dispatch(QueueName.TelegramNotificationJob, {
        //     message: `Job failed: ${queue.name} - ${error.message} (RequestId: ${requestId})`,
        //   });
        // }
      });
    });
  }
}

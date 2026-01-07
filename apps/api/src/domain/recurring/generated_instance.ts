import { AggregateRoot, Criteria } from "@abejarano/ts-mongodb-criteria";

export type GeneratedInstancePrimitives = {
  id?: string;
  instanceId: string;
  ruleId: string;
  userId: string;
  date: Date;
  transactionId: string;
  uniqueKey: string; // ruleId_dateISO
};

export class GeneratedInstance extends AggregateRoot {
  constructor(private readonly props: GeneratedInstancePrimitives) {
    super();
  }

  static fromPrimitives(props: GeneratedInstancePrimitives): GeneratedInstance {
    return new GeneratedInstance(props);
  }

  static create(
    id: string,
    instanceId: string,
    ruleId: string,
    userId: string,
    date: Date,
    transactionId: string,
  ): GeneratedInstance {
    // Normalize date to YYYY-MM-DD for unique key
    const dateStr = date.toISOString().split("T")[0];
    const uniqueKey = `${ruleId}_${dateStr}`;

    return new GeneratedInstance({
      id,
      instanceId,
      ruleId,
      userId,
      date,
      transactionId,
      uniqueKey,
    });
  }

  toPrimitives(): GeneratedInstancePrimitives {
    return { ...this.props };
  }

  get id(): string | undefined {
    return this.props.id;
  }
  
  get instanceId(): string {
    return this.props.instanceId;
  }

  getId(): string {
    return this.props.id ?? this.props.instanceId;
  }
}

export interface GeneratedInstanceRepository {
  upsert(instance: GeneratedInstance): Promise<void>;
  search(criteria: Criteria): Promise<GeneratedInstance[]>;
}

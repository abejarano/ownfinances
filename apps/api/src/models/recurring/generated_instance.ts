import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";
import { createMongoId } from "../shared/mongo_id";

export type GeneratedInstancePrimitives = {
  id?: string;
  recurringRuleId: string;
  userId: string;
  date: Date;
  transactionId: string;
  uniqueKey: string; // recurringRuleId_dateISO
};

export class GeneratedInstance extends AggregateRoot {
  private constructor(private readonly props: GeneratedInstancePrimitives) {
    super();
  }

  static fromPrimitives(props: GeneratedInstancePrimitives): GeneratedInstance {
    return new GeneratedInstance(props);
  }

  static create(
    recurringRuleId: string,
    userId: string,
    date: Date,
    transactionId: string
  ): GeneratedInstance {
    // Normalize date to YYYY-MM-DD for unique key
    const dateStr = date.toISOString().split("T")[0];
    const uniqueKey = `${recurringRuleId}_${dateStr}`;

    return new GeneratedInstance({
      id: createMongoId(),
      recurringRuleId,
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

  getId(): string {
    return this.props.id ?? this.props.uniqueKey;
  }
}

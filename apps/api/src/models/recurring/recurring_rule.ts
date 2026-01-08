import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";
import { createMongoId } from "../shared/mongo_id";
import { TransactionType } from "../transaction";

export enum RecurringFrequency {
  Weekly = "weekly",
  Monthly = "monthly",
  Yearly = "yearly",
}

export interface RecurringTemplate {
  type: TransactionType;
  amount: number;
  currency: string;
  categoryId?: string;
  fromAccountId?: string;
  toAccountId?: string;
  note?: string;
  tags?: string[];
}

export type RecurringRulePrimitives = {
  id?: string;
  recurringRuleId: string;
  userId: string;
  signature: string;
  frequency: RecurringFrequency;
  interval: number;
  startDate: Date;
  endDate?: Date;
  template: RecurringTemplate;
  isActive: boolean;
  lastRunAt?: Date;
};

export type RecurringRuleCreateProps = {
  userId: string;
  signature: string;
  frequency: RecurringFrequency;
  interval: number;
  startDate: Date;
  endDate?: Date;
  template: RecurringTemplate;
  isActive?: boolean;
  lastRunAt?: Date;
};

export class RecurringRule extends AggregateRoot {
  private constructor(private readonly props: RecurringRulePrimitives) {
    super();
  }

  static create(props: RecurringRuleCreateProps): RecurringRule {
    return new RecurringRule({
      recurringRuleId: createMongoId(),
      userId: props.userId,
      signature: props.signature,
      frequency: props.frequency,
      interval: props.interval,
      startDate: props.startDate,
      endDate: props.endDate,
      template: props.template,
      isActive: props.isActive ?? true,
      lastRunAt: props.lastRunAt,
    });
  }

  static fromPrimitives(props: RecurringRulePrimitives): RecurringRule {
    return new RecurringRule(props);
  }

  toPrimitives(): RecurringRulePrimitives {
    return { ...this.props };
  }

  get id(): string | undefined {
    return this.props.id;
  }

  get ruleId(): string {
    return this.props.recurringRuleId;
  }

  getId(): string {
    return this.props.id ?? this.props.recurringRuleId;
  }

  get userId(): string {
    return this.props.userId;
  }

  get frequency(): RecurringFrequency {
    return this.props.frequency;
  }

  get interval(): number {
    return this.props.interval;
  }

  get startDate(): Date {
    return this.props.startDate;
  }

  get endDate(): Date | undefined {
    return this.props.endDate;
  }

  get template(): RecurringTemplate {
    return this.props.template;
  }

  get isActive(): boolean {
    return this.props.isActive;
  }
}

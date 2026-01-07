import { AggregateRoot, Criteria, Paginate } from "@abejarano/ts-mongodb-criteria";

export type RecurringFrequency = "weekly" | "monthly" | "yearly";

export interface RecurringTemplate {
  type: "income" | "expense" | "transfer";
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
  ruleId: string;
  userId: string;
  frequency: RecurringFrequency;
  interval: number;
  startDate: Date;
  endDate?: Date;
  template: RecurringTemplate;
  active: boolean;
  lastRunAt?: Date;
};

export class RecurringRule extends AggregateRoot {
  constructor(private readonly props: RecurringRulePrimitives) {
    super();
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
    return this.props.ruleId;
  }

  getId(): string {
    return this.props.id ?? this.props.ruleId;
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
    return this.props.active;
  }
}

export interface RecurringRuleRepository {
  upsert(rule: RecurringRule): Promise<void>;
  list(criteria: Criteria): Promise<Paginate<RecurringRule>>;
  byId(ruleId: string): Promise<RecurringRule | undefined>;
  remove(ruleId: string): Promise<void>;
}

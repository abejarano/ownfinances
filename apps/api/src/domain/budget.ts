import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";

export type BudgetPeriodType = "monthly" | "quarterly" | "semiannual" | "annual";

export type BudgetLine = {
  categoryId: string;
  plannedAmount: number;
};

export type BudgetPrimitives = {
  id?: string;
  budgetId: string;
  userId: string;
  periodType: BudgetPeriodType;
  startDate: Date;
  endDate: Date;
  lines: BudgetLine[];
  createdAt: Date;
  updatedAt?: Date;
};

export class Budget extends AggregateRoot {
  constructor(private readonly props: BudgetPrimitives) {
    super();
  }

  getId(): string {
    return this.props.id ?? this.props.budgetId;
  }

  getBudgetId(): string {
    return this.props.budgetId;
  }

  toPrimitives(): BudgetPrimitives {
    return this.props;
  }

  static fromPrimitives(primitives: BudgetPrimitives): Budget {
    return new Budget(primitives);
  }
}

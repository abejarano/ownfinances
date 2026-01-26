import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "./shared/mongo_id"

export type BudgetPeriodType = "monthly" | "quarterly" | "semiannual" | "annual"

export type BudgetLine = {
  categoryId: string
  plannedAmount: number
}

export type BudgetDebtPayment = {
  debtId: string
  plannedAmount: number
}

export type BudgetPrimitives = {
  id?: string
  budgetId: string
  userId: string
  periodType: BudgetPeriodType
  startDate: Date
  endDate: Date
  lines: BudgetLine[]
  debtPayments?: BudgetDebtPayment[]
  createdAt: Date
  updatedAt?: Date
}

export type BudgetCreateProps = {
  userId: string
  periodType: BudgetPeriodType
  startDate: Date
  endDate: Date
  lines?: BudgetLine[]
  debtPayments?: BudgetDebtPayment[]
}

export class Budget extends AggregateRoot {
  private constructor(private readonly props: BudgetPrimitives) {
    super()
  }

  static create(props: BudgetCreateProps): Budget {
    const now = new Date()

    return new Budget({
      budgetId: createMongoId(),
      userId: props.userId,
      periodType: props.periodType,
      startDate: props.startDate,
      endDate: props.endDate,
      lines: props.lines ?? [],
      debtPayments: props.debtPayments ?? [],
      createdAt: now,
      updatedAt: now,
    })
  }

  getId(): string {
    return this.props.id ?? this.props.budgetId
  }

  getBudgetId(): string {
    return this.props.budgetId
  }

  toPrimitives(): BudgetPrimitives {
    return this.props
  }

  static override fromPrimitives(primitives: BudgetPrimitives): Budget {
    return new Budget({
      ...primitives,
      debtPayments: primitives.debtPayments ?? [],
    })
  }
}

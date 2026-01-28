import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "./shared/mongo_id"

export type BudgetPeriodType = "monthly" | "quarterly" | "semiannual" | "annual"

export type BudgetPlanEntry = {
  entryId: string
  amount: number
  description?: string | null
  createdAt: Date
}

export type BudgetCategoryPlan = {
  categoryId: string
  plannedTotal: number
  entries: BudgetPlanEntry[]
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
  categories: BudgetCategoryPlan[]
  debtPayments?: BudgetDebtPayment[]
  createdAt: Date
  updatedAt?: Date
}

export type BudgetCreateProps = {
  userId: string
  periodType: BudgetPeriodType
  startDate: Date
  endDate: Date
  categories?: BudgetCategoryPlan[]
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
      categories: props.categories ?? [],
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
      categories: primitives.categories ?? [],
      debtPayments: primitives.debtPayments ?? [],
    })
  }
}

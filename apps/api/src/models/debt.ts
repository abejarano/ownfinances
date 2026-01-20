import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "./shared/mongo_id"

export enum DebtType {
  CreditCard = "credit_card",
  Loan = "loan",
  Other = "other",
}

export type DebtPrimitives = {
  id?: string
  debtId: string
  userId: string
  name: string
  type: DebtType
  linkedAccountId?: string
  paymentAccountId?: string
  currency: string
  currentBalance: number
  initialBalance?: number
  dueDay?: number
  minimumPayment?: number
  interestRateAnnual?: number
  isActive: boolean
  createdAt: Date
  updatedAt?: Date
  amountDue?: number
  creditBalance?: number
}

export type DebtCreateProps = {
  userId: string
  name: string
  type: DebtType
  linkedAccountId?: string
  paymentAccountId?: string
  currency?: string
  dueDay?: number
  minimumPayment?: number
  interestRateAnnual?: number
  initialBalance?: number
  isActive?: boolean
}

export class Debt extends AggregateRoot {
  private readonly props: DebtPrimitives

  private constructor(props: DebtPrimitives) {
    super()
    this.props = props
  }

  static create(props: DebtCreateProps): Debt {
    const now = new Date()
    return new Debt({
      debtId: createMongoId(),
      userId: props.userId,
      name: props.name,
      type: props.type,
      linkedAccountId: props.linkedAccountId,
      paymentAccountId: props.paymentAccountId,
  currency: props.currency ?? "BRL",
      currentBalance: 0,
      initialBalance: props.initialBalance ?? 0,
      dueDay: props.dueDay,
      minimumPayment: props.minimumPayment,
      interestRateAnnual: props.interestRateAnnual,
      isActive: props.isActive ?? true,
      createdAt: now,
      updatedAt: now,
    })
  }

  static override fromPrimitives(primitives: DebtPrimitives): Debt {
    return new Debt(primitives)
  }

  toPrimitives(): DebtPrimitives {
    return this.props
  }

  getId(): string {
    return this.props.id ?? this.props.debtId
  }

  getDebtId(): string {
    return this.props.debtId
  }
}

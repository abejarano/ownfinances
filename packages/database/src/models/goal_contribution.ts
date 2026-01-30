import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "./shared/mongo_id"

export type GoalContributionPrimitives = {
  id?: string
  goalContributionId: string
  userId: string
  goalId: string
  date: Date
  amount: number
  accountId?: string
  note?: string | null
  createdAt: Date
  updatedAt?: Date
}

export type GoalContributionCreateProps = {
  userId: string
  goalId: string
  date?: Date
  amount: number
  accountId?: string
  note?: string | null
}

export class GoalContribution extends AggregateRoot {
  private readonly props: GoalContributionPrimitives

  private constructor(props: GoalContributionPrimitives) {
    super()
    this.props = props
  }

  static create(props: GoalContributionCreateProps): GoalContribution {
    const now = new Date()
    return new GoalContribution({
      goalContributionId: createMongoId(),
      userId: props.userId,
      goalId: props.goalId,
      date: props.date ?? now,
      amount: props.amount,
      accountId: props.accountId,
      note: props.note,
      createdAt: now,
      updatedAt: now,
    })
  }

  static override fromPrimitives(
    primitives: GoalContributionPrimitives
  ): GoalContribution {
    return new GoalContribution(primitives)
  }

  toPrimitives(): GoalContributionPrimitives {
    return this.props
  }

  getId(): string {
    return this.props.id ?? this.props.goalContributionId
  }

  getGoalContributionId(): string {
    return this.props.goalContributionId
  }
}

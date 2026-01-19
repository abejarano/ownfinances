import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "../shared/mongo_id"

export type GeneratedInstancePrimitives = {
  id?: string
  generatedInstanceId: string
  recurringRuleId: string
  userId: string
  date: Date
  transactionId?: string
  uniqueKey: string // recurringRuleId_dateISO
  status: "created" | "ignored"
}

export class GeneratedInstance extends AggregateRoot {
  private constructor(private readonly props: GeneratedInstancePrimitives) {
    super()
  }

  getId(): string {
    return this.props.id ?? this.props.generatedInstanceId
  }

  static override fromPrimitives(
    props: GeneratedInstancePrimitives
  ): GeneratedInstance {
    return new GeneratedInstance(props)
  }

  static create(
    recurringRuleId: string,
    userId: string,
    date: Date,
    transactionId?: string,
    status: "created" | "ignored" = "created"
  ): GeneratedInstance {
    // Normalize date to YYYY-MM-DD for unique key
    const dateStr = date.toISOString().split("T")[0]
    const uniqueKey = `${recurringRuleId}_${dateStr}`

    return new GeneratedInstance({
      generatedInstanceId: createMongoId(),
      recurringRuleId,
      userId,
      date,
      transactionId,
      uniqueKey,
      status,
    })
  }

  getUniqueKey(): string {
    return this.props.uniqueKey
  }

  toPrimitives(): GeneratedInstancePrimitives {
    return { ...this.props }
  }
}

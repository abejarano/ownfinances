import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "../shared/mongo_id"
import { TransactionType } from "../transaction"

export type TransactionTemplatePrimitives = {
  id?: string
  templateId: string
  userId: string
  name: string // "Netflix", "Aluguel", etc.
  type: TransactionType
  amount: number
  currency: string
  categoryId?: string
  fromAccountId?: string
  toAccountId?: string
  note?: string
  tags?: string[]
  createdAt: Date
  updatedAt: Date
}

export type TransactionTemplateCreateProps = {
  userId: string
  name: string
  type: TransactionType
  amount: number
  currency?: string
  categoryId?: string
  fromAccountId?: string
  toAccountId?: string
  note?: string
  tags?: string[]
}

export class TransactionTemplate extends AggregateRoot {
  private constructor(private readonly props: TransactionTemplatePrimitives) {
    super()
  }

  static create(props: TransactionTemplateCreateProps): TransactionTemplate {
    const now = new Date()

    return new TransactionTemplate({
      templateId: createMongoId(),
      userId: props.userId,
      name: props.name,
      type: props.type,
      amount: props.amount,
      currency: props.currency ?? "BRL",
      categoryId: props.categoryId,
      fromAccountId: props.fromAccountId,
      toAccountId: props.toAccountId,
      note: props.note,
      tags: props.tags,
      createdAt: now,
      updatedAt: now,
    })
  }

  static override fromPrimitives(
    props: TransactionTemplatePrimitives
  ): TransactionTemplate {
    return new TransactionTemplate(props)
  }

  toPrimitives(): TransactionTemplatePrimitives {
    return { ...this.props }
  }

  get id(): string | undefined {
    return this.props.id
  }

  get templateId(): string {
    return this.props.templateId
  }

  getId(): string {
    return this.props.id ?? this.props.templateId
  }

  get userId(): string {
    return this.props.userId
  }

  get name(): string {
    return this.props.name
  }
}

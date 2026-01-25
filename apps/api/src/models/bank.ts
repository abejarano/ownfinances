import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "./shared/mongo_id"

export type BankPrimitives = {
  id?: string
  bankId: string
  name: string
  code: string // unique code per country or global? usually per country.
  country: string // ISO code: BR, VE, CO, AR, US
  logoUrl?: string
  isActive: boolean
  createdAt: Date
  updatedAt?: Date
}

export class Bank extends AggregateRoot {
  override getId(): string {
    return this.props.id ?? this.props.bankId
  }
  private readonly props: BankPrimitives

  private constructor(props: BankPrimitives) {
    super()
    this.props = props
  }

  static create(props: {
    name: string
    code: string
    country: string
    logoUrl?: string
  }): Bank {
    const now = new Date()
    return new Bank({
      bankId: createMongoId(),
      name: props.name,
      code: props.code,
      country: props.country,
      logoUrl: props.logoUrl,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    })
  }

  toPrimitives(): BankPrimitives {
    return this.props
  }

  static override fromPrimitives(primitives: BankPrimitives): Bank {
    return new Bank(primitives)
  }
}

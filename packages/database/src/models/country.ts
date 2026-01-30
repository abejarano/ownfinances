import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "./shared/mongo_id"

export type CountryPrimitives = {
  id?: string
  countryId: string
  name: string
  code: string
  isActive: boolean
  createdAt: Date
  updatedAt?: Date
}

export class Country extends AggregateRoot {
  override getId(): string {
    return this.props.id ?? this.props.countryId
  }

  private readonly props: CountryPrimitives

  private constructor(props: CountryPrimitives) {
    super()
    this.props = props
  }

  static create(props: { name: string; code: string }): Country {
    const now = new Date()
    return new Country({
      countryId: createMongoId(),
      name: props.name,
      code: props.code,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    })
  }

  toPrimitives(): CountryPrimitives {
    return this.props
  }

  static override fromPrimitives(primitives: CountryPrimitives): Country {
    return new Country(primitives)
  }
}

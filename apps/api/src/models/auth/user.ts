import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "../shared/mongo_id"

export type UserPrimitives = {
  id?: string
  userId: string
  email: string
  name?: string | null
  passwordHash: string
  googleId?: string | null
  appleId?: string | null
  createdAt: Date
  updatedAt?: Date
  lastLoginAt?: Date
}

export class User extends AggregateRoot {
  private constructor(private readonly props: UserPrimitives) {
    super()
  }

  static create(props: {
    email: string
    name?: string | null
    passwordHash: string
    googleId?: string | null
    appleId?: string | null
  }): User {
    const now = new Date()

    return new User({
      userId: createMongoId(),
      email: props.email,
      name: props.name ?? null,
      passwordHash: props.passwordHash,
      googleId: props.googleId ?? null,
      appleId: props.appleId ?? null,
      createdAt: now,
      updatedAt: now,
    })
  }

  getId(): string {
    return this.props.id ?? this.props.userId
  }

  getUserId(): string {
    return this.props.userId
  }

  getName() {
    return this.props.name
  }

  getEmail() {
    return this.props.email
  }

  toPrimitives(): UserPrimitives {
    return this.props
  }

  static override fromPrimitives(primitives: UserPrimitives): User {
    return new User(primitives)
  }
}

import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";
import { createMongoId } from "../shared/mongo_id";

export type UserPrimitives = {
  id?: string;
  userId: string;
  email: string;
  name: string;
  passwordHash: string;
  googleId?: string | null;
  appleId?: string | null;
  createdAt: Date;
  updatedAt?: Date;
  lastLoginAt?: Date;
};

export class User extends AggregateRoot {
  private constructor(private readonly props: UserPrimitives) {
    super();
  }

  static create(props: {
    email: string;
    name: string;
    passwordHash: string;
    googleId?: string | null;
    appleId?: string | null;
  }): User {
    const now = new Date();
    const data: UserPrimitives = {
      userId: createMongoId(),
      email: props.email,
      name: props.name ?? null,
      passwordHash: props.passwordHash,
      createdAt: now,
      updatedAt: now,
    };

    if (props.googleId != null) {
      data.googleId = props.googleId;
    }
    if (props.appleId != null) {
      data.appleId = props.appleId;
    }

    return new User(data);
  }

  static override fromPrimitives(primitives: UserPrimitives): User {
    return new User(primitives);
  }

  getId(): string {
    return this.props.id ?? this.props.userId;
  }

  getUserId(): string {
    return this.props.userId;
  }

  getName() {
    return this.props.name;
  }

  getEmail() {
    return this.props.email;
  }

  toPrimitives(): UserPrimitives {
    return this.props;
  }
}

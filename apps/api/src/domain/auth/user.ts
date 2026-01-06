import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";

export type UserPrimitives = {
  id?: string;
  userId: string;
  email: string;
  name?: string | null;
  passwordHash: string;
  createdAt: Date;
  updatedAt?: Date;
  lastLoginAt?: Date;
};

export class User extends AggregateRoot {
  constructor(private readonly props: UserPrimitives) {
    super();
  }

  getId(): string {
    return this.props.id ?? this.props.userId;
  }

  getUserId(): string {
    return this.props.userId;
  }

  toPrimitives(): UserPrimitives {
    return this.props;
  }

  static fromPrimitives(primitives: UserPrimitives): User {
    return new User(primitives);
  }
}

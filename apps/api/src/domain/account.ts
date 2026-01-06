import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";

export type AccountType =
  | "cash"
  | "bank"
  | "wallet"
  | "broker"
  | "credit_card";

export type AccountPrimitives = {
  id?: string;
  accountId: string;
  userId: string;
  name: string;
  type: AccountType;
  currency: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt?: Date;
};

export class Account extends AggregateRoot {
  private readonly props: AccountPrimitives;

  constructor(props: AccountPrimitives) {
    super();
    this.props = props;
  }

  getId(): string {
    return this.props.id ?? this.props.accountId;
  }

  getAccountId(): string {
    return this.props.accountId;
  }

  toPrimitives(): AccountPrimitives {
    return this.props;
  }

  static fromPrimitives(primitives: AccountPrimitives): Account {
    return new Account(primitives);
  }
}

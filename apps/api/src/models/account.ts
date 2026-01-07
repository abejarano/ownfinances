import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";
import { createMongoId } from "./shared/mongo_id";

export enum AccountType {
  Cash = "cash",
  Bank = "bank",
  Wallet = "wallet",
  Broker = "broker",
  CreditCard = "credit_card",
}

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

export type AccountCreateProps = {
  userId: string;
  name: string;
  type: AccountType;
  currency?: string;
  isActive?: boolean;
};

export class Account extends AggregateRoot {
  private readonly props: AccountPrimitives;

  private constructor(props: AccountPrimitives) {
    super();
    this.props = props;
  }

  static create(props: AccountCreateProps): Account {
    const now = new Date();

    return new Account({
      accountId: createMongoId(),
      userId: props.userId,
      name: props.name,
      type: props.type,
      currency: props.currency ?? "BRL",
      isActive: props.isActive ?? true,
      createdAt: now,
      updatedAt: now,
    });
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

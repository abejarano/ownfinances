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
  bankType?: string | null;
  currency: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt?: Date;
};

export type AccountCreateProps = {
  userId: string;
  name: string;
  type: AccountType;
  bankType?: string | null;
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
      bankType: props.bankType,
      currency: props.currency ?? "BRL",
      isActive: props.isActive ?? true,
      createdAt: now,
      updatedAt: now,
    });
  }

  static override fromPrimitives(primitives: AccountPrimitives): Account {
    return new Account(primitives);
  }

  getId(): string {
    return this.props.id ?? this.props.accountId;
  }

  getAccountId(): string {
    return this.props.accountId;
  }

  getBankType(): string | null {
    return this.props.bankType ?? null;
  }

  getType(): AccountType {
    return this.props.type;
  }

  toPrimitives(): AccountPrimitives {
    return this.props;
  }

  getCurrencry() {
    return this.props.currency;
  }
}

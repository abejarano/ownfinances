import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";
import { createMongoId } from "./shared/mongo_id";

export enum TransactionType {
  Income = "income",
  Expense = "expense",
  Transfer = "transfer",
}

export type TransactionStatus = "pending" | "cleared";

export type TransactionPrimitives = {
  id?: string;
  transactionId: string;
  userId: string;
  type: TransactionType;
  date: Date;
  amount: number;
  currency: string;
  categoryId?: string | null;
  fromAccountId?: string | null;
  toAccountId?: string | null;
  note?: string | null;
  tags?: string[] | null;
  status: TransactionStatus;
  clearedAt?: Date | null;
  createdAt: Date;
  updatedAt?: Date;
  deletedAt?: Date | null;
  recurringRuleId?: string;
};

export type TransactionCreateProps = {
  userId: string;
  type: TransactionType;
  date: Date;
  amount: number;
  currency: string;
  categoryId?: string | null;
  fromAccountId?: string | null;
  toAccountId?: string | null;
  note?: string | null;
  tags?: string[] | null;
  status?: TransactionStatus;
  clearedAt?: Date | null;
  recurringRuleId?: string;
};

export class Transaction extends AggregateRoot {
  private readonly props: TransactionPrimitives;

  private constructor(props: TransactionPrimitives) {
    super();
    this.props = props;
  }

  static create(props: TransactionCreateProps): Transaction {
    const now = new Date();
    const status = props.status ?? "pending";
    const clearedAt = status === "cleared" ? props.clearedAt ?? now : null;

    return new Transaction({
      userId: props.userId,
      type: props.type,
      date: props.date,
      amount: props.amount,
      currency: props.currency,
      categoryId: props.categoryId ?? null,
      fromAccountId: props.fromAccountId ?? null,
      toAccountId: props.toAccountId ?? null,
      note: props.note ?? null,
      tags: props.tags ?? null,
      status,
      clearedAt,
      recurringRuleId: props.recurringRuleId,
      transactionId: createMongoId(),
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    });
  }

  getId(): string {
    return this.props.id ?? this.props.transactionId;
  }

  getTransactionId(): string {
    return this.props.transactionId;
  }

  toPrimitives(): TransactionPrimitives {
    return this.props;
  }

  static fromPrimitives(primitives: TransactionPrimitives): Transaction {
    return new Transaction(primitives);
  }
}

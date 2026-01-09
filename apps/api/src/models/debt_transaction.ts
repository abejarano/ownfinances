import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";
import { createMongoId } from "./shared/mongo_id";

export enum DebtTransactionType {
  Charge = "charge",
  Payment = "payment",
  Fee = "fee",
  Interest = "interest",
}

export type DebtTransactionPrimitives = {
  id?: string;
  debtTransactionId: string;
  userId: string;
  debtId: string;
  date: Date;
  type: DebtTransactionType;
  amount: number;
  accountId?: string;
  categoryId?: string | null;
  note?: string | null;
  createdAt: Date;
  updatedAt?: Date;
};

export type DebtTransactionCreateProps = {
  userId: string;
  debtId: string;
  date?: Date;
  type: DebtTransactionType;
  amount: number;
  accountId?: string;
  categoryId?: string | null;
  note?: string | null;
};

export class DebtTransaction extends AggregateRoot {
  private readonly props: DebtTransactionPrimitives;

  private constructor(props: DebtTransactionPrimitives) {
    super();
    this.props = props;
  }

  static create(props: DebtTransactionCreateProps): DebtTransaction {
    const now = new Date();
    return new DebtTransaction({
      debtTransactionId: createMongoId(),
      userId: props.userId,
      debtId: props.debtId,
      date: props.date ?? now,
      type: props.type,
      amount: props.amount,
      accountId: props.accountId,
      categoryId: props.categoryId ?? null,
      note: props.note,
      createdAt: now,
      updatedAt: now,
    });
  }

  static fromPrimitives(primitives: DebtTransactionPrimitives): DebtTransaction {
    return new DebtTransaction(primitives);
  }

  toPrimitives(): DebtTransactionPrimitives {
    return this.props;
  }

  getId(): string {
    return this.props.id ?? this.props.debtTransactionId;
  }

  getDebtTransactionId(): string {
    return this.props.debtTransactionId;
  }
}

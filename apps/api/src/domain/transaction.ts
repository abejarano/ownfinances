import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";

export type TransactionType = "income" | "expense" | "transfer";
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
  recurringRuleId?: string;
};

export class Transaction extends AggregateRoot {
  private readonly props: TransactionPrimitives;

  constructor(props: TransactionPrimitives) {
    super();
    this.props = props;
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

export interface TransactionRepository {
  upsert(transaction: Transaction): Promise<void>;
}

import { AggregateRoot, Criteria, Paginate } from "@abejarano/ts-mongodb-criteria";

export type TransactionTemplatePrimitives = {
  id?: string;
  templateId: string;
  userId: string;
  name: string; // "Netflix", "Aluguel", etc.
  type: "income" | "expense" | "transfer";
  amount: number;
  currency: string;
  categoryId?: string;
  fromAccountId?: string;
  toAccountId?: string;
  note?: string;
  tags?: string[];
  createdAt: Date;
  updatedAt: Date;
};

export class TransactionTemplate extends AggregateRoot {
  constructor(private readonly props: TransactionTemplatePrimitives) {
    super();
  }

  static fromPrimitives(props: TransactionTemplatePrimitives): TransactionTemplate {
    return new TransactionTemplate(props);
  }

  toPrimitives(): TransactionTemplatePrimitives {
    return { ...this.props };
  }

  get id(): string | undefined {
    return this.props.id;
  }

  get templateId(): string {
    return this.props.templateId;
  }

  getId(): string {
    return this.props.id ?? this.props.templateId;
  }

  get userId(): string {
    return this.props.userId;
  }

  get name(): string {
    return this.props.name;
  }
}

export interface TransactionTemplateRepository {
  upsert(template: TransactionTemplate): Promise<void>;
  list(criteria: Criteria): Promise<Paginate<TransactionTemplate>>;
  byId(templateId: string): Promise<TransactionTemplate | undefined>;
  remove(templateId: string): Promise<void>;
}

import { AggregateRoot } from "@abejarano/ts-mongodb-criteria";

export type CategoryKind = "income" | "expense";

export type CategoryPrimitives = {
  id?: string;
  categoryId: string;
  userId: string;
  name: string;
  kind: CategoryKind;
  parentId?: string | null;
  color?: string | null;
  icon?: string | null;
  isActive: boolean;
  createdAt: Date;
  updatedAt?: Date;
};

export class Category extends AggregateRoot {
  private readonly props: CategoryPrimitives;

  constructor(props: CategoryPrimitives) {
    super();
    this.props = props;
  }

  getId(): string {
    return this.props.id ?? this.props.categoryId;
  }

  getCategoryId(): string {
    return this.props.categoryId;
  }

  toPrimitives(): CategoryPrimitives {
    return this.props;
  }

  static fromPrimitives(primitives: CategoryPrimitives): Category {
    return new Category(primitives);
  }
}

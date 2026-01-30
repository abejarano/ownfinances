import { AggregateRoot } from "@abejarano/ts-mongodb-criteria"
import { createMongoId } from "./shared/mongo_id"

export type CategoryKind = "income" | "expense"

export type CategoryPrimitives = {
  id?: string
  categoryId: string
  userId: string
  name: string
  kind: CategoryKind
  parentId?: string | null
  color?: string | null
  icon?: string | null
  isActive: boolean
  createdAt: Date
  updatedAt?: Date
}

export type CategoryCreateProps = {
  userId: string
  name: string
  kind: CategoryKind
  parentId?: string | null
  color?: string | null
  icon?: string | null
  isActive?: boolean
}

export class Category extends AggregateRoot {
  private readonly props: CategoryPrimitives

  private constructor(props: CategoryPrimitives) {
    super()
    this.props = props
  }

  static create(props: CategoryCreateProps): Category {
    const now = new Date()

    return new Category({
      categoryId: createMongoId(),
      userId: props.userId,
      name: props.name,
      kind: props.kind,
      parentId: props.parentId ?? null,
      color: props.color ?? null,
      icon: props.icon ?? null,
      isActive: props.isActive ?? true,
      createdAt: now,
      updatedAt: now,
    })
  }

  getId(): string {
    return this.props.id ?? this.props.categoryId
  }

  getCategoryId(): string {
    return this.props.categoryId
  }

  toPrimitives(): CategoryPrimitives {
    return this.props
  }

  static override fromPrimitives(primitives: CategoryPrimitives): Category {
    return new Category(primitives)
  }
}

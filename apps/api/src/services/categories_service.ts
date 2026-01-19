import type { Result } from "../bootstrap/response"
import type {
  CategoryCreatePayload,
  CategoryUpdatePayload,
} from "../http/validation/categories.validation"
import type { CategoryPrimitives } from "../models/category"
import { Category } from "../models/category"
import type { CategoryMongoRepository } from "../repositories/category_repository"
import type { TransactionMongoRepository } from "../repositories/transaction_repository"

export class CategoriesService {
  constructor(
    private readonly categories: CategoryMongoRepository,
    private readonly transactions: TransactionMongoRepository
  ) {}

  async create(
    userId: string,
    payload: CategoryCreatePayload
  ): Promise<Result<{ category: CategoryPrimitives }>> {
    const category = Category.create({
      userId,
      name: payload.name!,
      kind: payload.kind!,
      parentId: payload.parentId ?? null,
      color: payload.color ?? null,
      icon: payload.icon ?? null,
      isActive: payload.isActive ?? true,
    })

    await this.categories.upsert(category)
    return { value: { category: category.toPrimitives() }, status: 201 }
  }

  async update(
    userId: string,
    categoryId: string,
    payload: CategoryUpdatePayload
  ): Promise<Result<{ category: CategoryPrimitives }>> {
    const existing = await this.categories.one({
      userId,
      categoryId,
    })
    if (!existing) {
      return { error: "Categoria no encontrada", status: 404 }
    }

    const existingPrimitives = existing.toPrimitives()
    const merged: CategoryPrimitives = {
      ...existingPrimitives,
      ...payload,
      id: existingPrimitives.id ?? existingPrimitives.categoryId,
      categoryId: existingPrimitives.categoryId,
      userId: existingPrimitives.userId,
      updatedAt: new Date(),
    }

    const category = Category.fromPrimitives(merged)
    await this.categories.upsert(category)
    return { value: { category: category.toPrimitives() }, status: 201 }
  }

  async remove(
    userId: string,
    categoryId: string
  ): Promise<Result<{ ok: boolean; deletedTransactions: number }>> {
    const existing = await this.categories.one({ userId, categoryId })
    if (!existing) {
      return { error: "Categoria no encontrada", status: 404 }
    }

    const deletedTransactions = await this.transactions.deleteManyByCategory(
      userId,
      categoryId
    )
    const deleted = await this.categories.delete(userId, categoryId)
    if (!deleted) {
      return { error: "Categoria no encontrada", status: 404 }
    }

    return { value: { ok: true, deletedTransactions }, status: 200 }
  }
}

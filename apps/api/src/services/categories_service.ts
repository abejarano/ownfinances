import type { CategoryPrimitives } from "../models/category";
import { Category } from "../models/category";
import type { CategoryMongoRepository } from "../repositories/category_repository";
import type {
  CategoryCreatePayload,
  CategoryUpdatePayload,
} from "../http/validation/categories.validation";

export class CategoriesService {
  constructor(private readonly categories: CategoryMongoRepository) {}

  async create(userId: string, payload: CategoryCreatePayload) {
    const category = Category.create({
      userId,
      name: payload.name!,
      kind: payload.kind!,
      parentId: payload.parentId ?? null,
      color: payload.color ?? null,
      icon: payload.icon ?? null,
      isActive: payload.isActive ?? true,
    });

    await this.categories.upsert(category);
    return { category: category.toPrimitives() };
  }

  async update(
    userId: string,
    categoryId: string,
    payload: CategoryUpdatePayload
  ) {
    const existing = await this.categories.one({
      userId,
      categoryId,
    });
    if (!existing) {
      return { error: "Categoria no encontrada", status: 404 };
    }

    const existingPrimitives = existing.toPrimitives();
    const merged: CategoryPrimitives = {
      ...existingPrimitives,
      ...payload,
      id: existingPrimitives.id ?? existingPrimitives.categoryId,
      categoryId: existingPrimitives.categoryId,
      userId: existingPrimitives.userId,
      updatedAt: new Date(),
    };

    const category = Category.fromPrimitives(merged);
    await this.categories.upsert(category);
    return { category: category.toPrimitives() };
  }

  async remove(userId: string, categoryId: string) {
    const deleted = await this.categories.delete(userId, categoryId);
    if (!deleted) {
      return { error: "Categoria no encontrada", status: 404 };
    }
    return { ok: true };
  }
}

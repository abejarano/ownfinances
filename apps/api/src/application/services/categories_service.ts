import type { CategoryPrimitives, CategoryKind } from "../../domain/category";
import { Category } from "../../domain/category";
import type { CategoryMongoRepository } from "../../repositories/category_repository";
import { ObjectId } from "mongodb";

export class CategoriesService {
  constructor(
    private readonly categories: CategoryMongoRepository,
    private readonly userId: string,
  ) {}

  async create(payload: Partial<CategoryPrimitives>) {
    const error = this.validate(payload, false);
    if (error) return { error };

    const now = new Date();
    const newId = new ObjectId().toHexString();
    const category = new Category({
      id: newId,
      categoryId: newId,
      userId: this.userId,
      name: payload.name!,
      kind: payload.kind!,
      parentId: payload.parentId ?? null,
      color: payload.color ?? null,
      icon: payload.icon ?? null,
      isActive: payload.isActive ?? true,
      createdAt: now,
      updatedAt: now,
    });

    await this.categories.upsert(category);
    return { category: category.toPrimitives() };
  }

  async update(categoryId: string, payload: Partial<CategoryPrimitives>) {
    const existing = await this.categories.one({
      userId: this.userId,
      categoryId,
    });
    if (!existing) {
      return { error: "Categoria no encontrada", status: 404 };
    }

    const merged: CategoryPrimitives = {
      ...existing,
      ...payload,
      id: existing.id ?? existing.categoryId,
      categoryId: existing.categoryId,
      userId: existing.userId,
      updatedAt: new Date(),
    };

    const error = this.validate(merged, true);
    if (error) return { error };

    const category = Category.fromPrimitives(merged);
    await this.categories.upsert(category);
    return { category: category.toPrimitives() };
  }

  async remove(categoryId: string) {
    const deleted = await this.categories.delete(this.userId, categoryId);
    if (!deleted) {
      return { error: "Categoria no encontrada", status: 404 };
    }
    return { ok: true };
  }

  private validate(
    payload: Partial<CategoryPrimitives>,
    isUpdate: boolean,
  ): string | null {
    if (!isUpdate && !payload.name) {
      return "Falta el nombre de la categoria";
    }
    if (payload.kind && !isCategoryKind(payload.kind)) {
      return "Tipo de categoria invalido";
    }
    if (!isUpdate && !payload.kind) {
      return "Tipo de categoria invalido";
    }
    return null;
  }
}

function isCategoryKind(value: string): value is CategoryKind {
  return value === "income" || value === "expense";
}

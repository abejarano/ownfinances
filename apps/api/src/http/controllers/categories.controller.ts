import type { CategoryMongoRepository } from "../../repositories/category_repository";
import { Category } from "../../models/category";
import type { CategoryPrimitives } from "../../models/category";
import type { CategoriesService } from "../../services/categories_service";
import { buildCategoriesCriteria } from "../criteria/categories.criteria";
import { badRequest, notFound } from "../errors";
import type {
  CategoryCreatePayload,
  CategoryUpdatePayload,
} from "../validation/categories.validation";

export class CategoriesController {
  constructor(
    private readonly repo: CategoryMongoRepository,
    private readonly service: CategoriesService,
  ) {}

  async list({
    query,
    userId,
  }: {
    query: Record<string, string | undefined>;
    userId?: string;
  }) {
    const criteria = buildCategoriesCriteria(query, userId ?? "");
    const result = await this.repo.list<CategoryPrimitives>(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Category.fromPrimitives(item).toPrimitives(),
      ),
    };
  }

  async create({
    body,
    set,
    userId,
  }: {
    body: CategoryCreatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { category } = await this.service.create(userId ?? "", body);
    return category!;
  }

  async getById({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const category = await this.repo.one({
      userId: userId ?? "",
      categoryId: params.id,
    });
    if (!category) return notFound(set, "Categoria no encontrada");
    return category.toPrimitives();
  }

  async update({
    params,
    body,
    set,
    userId,
  }: {
    params: { id: string };
    body: CategoryUpdatePayload;
    set: { status: number };
    userId?: string;
  }) {
    const { category, error, status } = await this.service.update(
      userId ?? "",
      params.id,
      body,
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return category!;
  }

  async remove({
    params,
    set,
    userId,
  }: {
    params: { id: string };
    set: { status: number };
    userId?: string;
  }) {
    const { ok, error, status } = await this.service.remove(
      userId ?? "",
      params.id,
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return { ok: ok === true };
  }
}

import type { CategoryMongoRepository } from "../../repositories/category_repository";
import { Category } from "../../domain/category";
import type { CategoriesService } from "../../application/services/categories_service";
import { buildCategoriesCriteria } from "../criteria/categories.criteria";
import { badRequest, notFound } from "../errors";

export class CategoriesController {
  constructor(
    private readonly repo: CategoryMongoRepository,
    private readonly service: CategoriesService,
    private readonly userId: string,
  ) {}

  list = async ({ query }: { query: Record<string, string | undefined> }) => {
    const criteria = buildCategoriesCriteria(query, this.userId);
    const result = await this.repo.list(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Category.fromPrimitives(item).toPrimitives(),
      ),
    };
  };

  create = async ({ body, set }: { body: unknown; set: { status: number } }) => {
    const { category, error } = await this.service.create(
      body as Record<string, unknown>,
    );
    if (error) return badRequest(set, error);
    return category!;
  };

  getById = async ({ params, set }: { params: { id: string }; set: { status: number } }) => {
    const category = await this.repo.one({ userId: this.userId, categoryId: params.id });
    if (!category) return notFound(set, "Categoria no encontrada");
    return Category.fromPrimitives(category).toPrimitives();
  };

  update = async ({ params, body, set }: { params: { id: string }; body: unknown; set: { status: number } }) => {
    const { category, error, status } = await this.service.update(
      params.id,
      body as Record<string, unknown>,
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return category!;
  };

  remove = async ({ params, set }: { params: { id: string }; set: { status: number } }) => {
    const { ok, error, status } = await this.service.remove(params.id);
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return { ok: ok === true };
  };
}

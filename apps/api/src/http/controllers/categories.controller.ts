import type { CategoryMongoRepository } from "../../repositories/category_repository";
import { Category } from "../../domain/category";
import type { CategoriesService } from "../../application/services/categories_service";
import { buildCategoriesCriteria } from "../criteria/categories.criteria";
import { badRequest, notFound } from "../errors";

export class CategoriesController {
  constructor(
    private readonly repo: CategoryMongoRepository,
    private readonly service: CategoriesService,
  ) {}

  list = async ({ query, userId }: { query: Record<string, string | undefined>; userId?: string }) => {
    const criteria = buildCategoriesCriteria(query, userId ?? "");
    const result = await this.repo.list(criteria);
    return {
      ...result,
      results: result.results.map((item) =>
        Category.fromPrimitives(item).toPrimitives(),
      ),
    };
  };

  create = async ({ body, set, userId }: { body: unknown; set: { status: number }; userId?: string }) => {
    const { category, error } = await this.service.create(
      userId ?? "",
      body as Record<string, unknown>,
    );
    if (error) return badRequest(set, error);
    return category!;
  };

  getById = async ({ params, set, userId }: { params: { id: string }; set: { status: number }; userId?: string }) => {
    const category = await this.repo.one({ userId: userId ?? "", categoryId: params.id });
    if (!category) return notFound(set, "Categoria no encontrada");
    return Category.fromPrimitives(category).toPrimitives();
  };

  update = async ({ params, body, set, userId }: { params: { id: string }; body: unknown; set: { status: number }; userId?: string }) => {
    const { category, error, status } = await this.service.update(
      userId ?? "",
      params.id,
      body as Record<string, unknown>,
    );
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return category!;
  };

  remove = async ({ params, set, userId }: { params: { id: string }; set: { status: number }; userId?: string }) => {
    const { ok, error, status } = await this.service.remove(userId ?? "", params.id);
    if (error) {
      if (status === 404) return notFound(set, error);
      return badRequest(set, error);
    }
    return { ok: ok === true };
  };
}

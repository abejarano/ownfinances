import type { CategoryPrimitives } from "@desquadra/database"
import { Category } from "@desquadra/database"
import type { CategoryMongoRepository } from "@desquadra/database"
import type { CategoriesService } from "../../services/categories_service"
import { buildCategoriesCriteria } from "../criteria/categories.criteria"
import {
  validateCategoryPayload,
  type CategoryCreatePayload,
  type CategoryUpdatePayload,
} from "../validation/categories.validation"

import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Req,
  Res,
  Use,
  type ServerResponse,
} from "bun-platform-kit"
import type { AuthenticatedRequest } from "../../@types/request"
import { Deps } from "../../bootstrap/deps"
import { HttpResponse } from "../../bootstrap/response"
import { AuthMiddleware } from "../middleware/auth.middleware"

@Controller("/categories")
export class CategoriesController {
  private repo: CategoryMongoRepository
  private service: CategoriesService

  constructor() {
    const deps = Deps.getInstance()
    this.repo = deps.categoryRepo
    this.service = deps.categoriesService
  }

  @Get("/")
  @Use([AuthMiddleware])
  async list(
    @Query() query: Record<string, string | undefined>,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const userId = req.userId
    const criteria = buildCategoriesCriteria(query, userId ?? "")
    const result = await this.repo.list<CategoryPrimitives>(criteria)
    return HttpResponse(res, {
      value: {
        nextPag: result.nextPag,
        count: result.count,
        results: result.results.map((item) =>
          Category.fromPrimitives(item).toPrimitives()
        ),
      },
      status: 200,
    })
  }

  @Post("/")
  @Use([AuthMiddleware, validateCategoryPayload(false)])
  async create(
    @Body() body: CategoryCreatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.create(req.userId ?? "", body)

    return HttpResponse(res, result)
  }

  @Get("/:id")
  @Use([AuthMiddleware])
  async getById(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const category = await this.repo.one({
      userId: req.userId ?? "",
      categoryId: id,
    })

    if (!category)
      return HttpResponse(res, {
        error: "Categoria no encontrada",
        status: 404,
      })

    return HttpResponse(res, { value: category.toPrimitives(), status: 200 })
  }

  @Put("/:id")
  @Use([AuthMiddleware, validateCategoryPayload(true)])
  async update(
    @Param("id") id: string,
    @Body() body: CategoryUpdatePayload,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.update(req.userId ?? "", id, body)

    return HttpResponse(res, result)
  }

  @Delete("/:id")
  @Use([AuthMiddleware])
  async remove(
    @Param("id") id: string,
    @Req() req: AuthenticatedRequest,
    @Res() res: ServerResponse
  ) {
    const result = await this.service.remove(req.userId ?? "", id)

    return HttpResponse(res, result)
  }
}
